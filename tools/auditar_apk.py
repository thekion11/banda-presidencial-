#!/usr/bin/env python3
"""Audita el AndroidManifest.xml de un APK (sin aapt): paquete, versión, minSdk/targetSdk, permisos, orientación, requisitos de hardware (Vulkan), depuración y respaldo,
tamaño por ABI y archivos. Avisa de lo que Google Play objetaría. Uso: python3 tools/auditar_apk.py build/presidente-debug.apk"""
import struct
import sys
import zipfile

OBJETIVO_MIN = 35  # Google Play: las apps nuevas deben apuntar al menos a Android 15 (API 35) desde el 31-ago-2025; revisar la exigencia vigente en Play Console


def _cadena(b: bytes, off: int, utf8: bool, sstart: int, offs: list, i: int) -> str:
    p = off + sstart + offs[i]
    if utf8:
        p += 1 + (1 if b[p] & 0x80 else 0)
        largo = b[p]
        p += 1
        if largo & 0x80:
            largo = ((largo & 0x7F) << 8) | b[p]
            p += 1
        return b[p:p + largo].decode("utf-8", "ignore")
    largo = struct.unpack_from("<H", b, p)[0]
    return b[p + 2:p + 2 + 2 * largo].decode("utf-16le", "ignore")


def manifiesto(b: bytes) -> list:
    """Lista de (etiqueta, {atributo: valor}) del AXML binario."""
    off = 8
    sp_size = struct.unpack_from("<I", b, off + 4)[0]
    n, _ns, flags, sstart, _ = struct.unpack_from("<IIIII", b, off + 8)
    offs = [struct.unpack_from("<I", b, off + 28 + 4 * i)[0] for i in range(n)]
    s = lambda i: _cadena(b, off, bool(flags & 0x100), sstart, offs, i)  # noqa: E731
    res, pos = [], off + sp_size
    while pos < len(b):
        t, _hs, sz = struct.unpack_from("<HHI", b, pos)
        if t == 0x0102:
            nombre = s(struct.unpack_from("<I", b, pos + 20)[0])
            ac = struct.unpack_from("<H", b, pos + 28)[0]
            atr = {}
            for i in range(ac):
                _ns2, an, rv, _vs, _r0, _dt, data = struct.unpack_from("<IIIHBBI", b, pos + 36 + 20 * i)
                atr[s(an)] = s(rv) if rv != 0xFFFFFFFF else data
            res.append((nombre, atr))
        pos += sz
    return res


def alineacion_elf(datos: bytes) -> int:
    """Menor alineación (p_align) de los segmentos PT_LOAD de un ELF de 64 bits; 0 si no es ELF64. Android 15 exige 16 KB (0x4000) para apuntar a API 35 o más."""
    if datos[:4] != b"\x7fELF" or datos[4] != 2:
        return 0
    phoff = struct.unpack_from("<Q", datos, 0x20)[0]
    phentsize, phnum = struct.unpack_from("<HH", datos, 0x36)
    menor = 0
    for i in range(phnum):
        base = phoff + i * phentsize
        tipo = struct.unpack_from("<I", datos, base)[0]
        if tipo == 1:
            alin = struct.unpack_from("<Q", datos, base + 0x30)[0]
            menor = alin if menor == 0 else min(menor, alin)
    return menor


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    z = zipfile.ZipFile(sys.argv[1])
    tags = manifiesto(z.read("AndroidManifest.xml"))
    avisos = []
    def uno(et):
        return next((a for n, a in tags if n == et), {})
    man, sdk, app = uno("manifest"), uno("uses-sdk"), uno("application")
    permisos = sorted(a.get("name", "?") for n, a in tags if n == "uses-permission")
    act = next((a for n, a in tags if n == "activity" and "GodotApp" in str(a.get("name", ""))), {})
    vulkan = [a for n, a in tags if n == "uses-feature" and "vulkan.version" in str(a.get("name", ""))]
    abis = sorted({i.filename.split("/")[1] for i in z.infolist() if i.filename.startswith("lib/") and i.filename.count("/") >= 2})
    tam_abi = {a: sum(i.compress_size for i in z.infolist() if i.filename.startswith(f"lib/{a}/")) // 1048576 for a in abis}
    print(f"paquete {man.get('package')} · versionCode {man.get('versionCode')} · versionName {man.get('versionName')} · compileSdk {man.get('compileSdkVersion')}")
    print(f"minSdk {sdk.get('minSdkVersion')} · targetSdk {sdk.get('targetSdkVersion')} · permisos {permisos or 'ninguno'}")
    print(f"orientación {act.get('screenOrientation')} (1 = vertical) · depurable {bool(app.get('debuggable'))} · respaldo {bool(app.get('allowBackup'))} · ABI {abis} · MB comprimidos por ABI {tam_abi}")
    print(f"requiere Vulkan: {[a.get('required') for a in vulkan] or 'no declarado'} · tamaño del APK {sum(i.compress_size for i in z.infolist()) // 1048576} MB")
    if int(sdk.get("targetSdkVersion", 0)) < OBJETIVO_MIN:
        avisos.append(f"targetSdk {sdk.get('targetSdkVersion')} < {OBJETIVO_MIN}: Play lo rechaza para apps nuevas")
    if "android.permission.INTERNET" in permisos:
        avisos.append("pide INTERNET: el juego es sin conexión y la política de privacidad dice que no usa red")
    otros = [p for p in permisos if p not in ("android.permission.DUMP",)]
    if otros:
        avisos.append(f"permisos a justificar: {otros}")
    if str(act.get("screenOrientation")) != "1":
        avisos.append("la orientación no está bloqueada en vertical")
    if any(a.get("required") is not False and a.get("required") not in ("false",) for a in vulkan):
        avisos.append("exige Vulkan: los teléfonos sin Vulkan 1.0 no podrán instalarlo (valorar el renderizador de compatibilidad)")
    if app.get("debuggable"):
        avisos.append("APK de depuración (debuggable): para Play hay que exportar en modo release y firmar con el keystore propio")
    if int(man.get("versionCode", 0)) < 1:
        avisos.append("versionCode inválido")
    for info in z.infolist():
        if info.filename.startswith("lib/") and info.filename.endswith(".so"):
            alin = alineacion_elf(z.read(info.filename))
            if alin and alin < 0x4000:
                avisos.append(f"{info.filename}: segmentos alineados a {alin // 1024} KB (Android 15 exige 16 KB para apuntar a API 35 o más)")
            elif alin:
                print(f"{info.filename}: alineación {alin // 1024} KB (16 KB o más: bien)")
    for a in avisos:
        print("AVISO:", a)
    return 0


if __name__ == "__main__":
    sys.exit(main())
