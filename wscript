import subprocess
import os

top = '.'
out = 'build'

ARM_SYSROOT = '/Applications/ArmGNUToolchain/15.2.rel1/arm-none-eabi/arm-none-eabi'

# All Pebble SDK platforms (including emery) use cortex-m3 / ARMv7-M soft-float
# in this community SDK build. Match exactly to avoid ABI mismatch at link time.
_SWIFT_TARGET = {
    'emery':  ('armv7-none-none-eabi', 'cortex-m3', None, 'soft'),
    'flint':  ('armv7-none-none-eabi', 'cortex-m3', None, 'soft'),
    'gabbro': ('armv7-none-none-eabi', 'cortex-m4', 'fpv4-sp-d16', 'hard'),
    'diorite':('armv7-none-none-eabi', 'cortex-m4', 'fpv4-sp-d16', 'hard'),
    'basalt': ('armv7-none-none-eabi', 'cortex-m4', 'fpv4-sp-d16', 'hard'),
    'chalk':  ('armv7-none-none-eabi', 'cortex-m4', 'fpv4-sp-d16', 'hard'),
    'aplite': ('armv7-none-none-eabi', 'cortex-m3', None,          'soft'),
}


def options(ctx):
    ctx.load('pebble_sdk')


def configure(ctx):
    ctx.load('pebble_sdk')

    swiftc = os.environ.get('SWIFTC', 'swiftc')
    try:
        r = subprocess.run([swiftc, '--version'], capture_output=True, text=True, check=True)
        ctx.env.SWIFTC = swiftc
        ctx.msg('Found swiftc', r.stdout.split('\n')[0].strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        ctx.fatal('swiftc not found. Install Swift 6.2+ from https://swift.org/download/')


def build(ctx):
    ctx.load('pebble_sdk')

    binaries = []
    cached_env = ctx.env

    for platform in ctx.env.TARGET_PLATFORMS:
        ctx.env = ctx.all_envs[platform]
        ctx.set_group(ctx.env.PLATFORM_NAME)

        build_dir  = ctx.env.BUILD_DIR          # e.g. 'emery'
        build_node = ctx.path.get_bld().make_node(build_dir)
        build_node.mkdir()

        swift_obj    = build_node.make_node('swift_app.o').abspath()
        swift_header = build_node.make_node('PebbleApp-Swift.h').abspath()

        triple, cpu, fpu, float_abi = _SWIFT_TARGET.get(
            platform, ('armv7em-none-none-eabi', 'cortex-m4', 'fpv4-sp-d16', 'hard'))

        swift_flags = [
            ctx.env.SWIFTC,
            '-enable-experimental-feature', 'Embedded',
            '-target', triple,
            '-Xcc', '-mcpu={}'.format(cpu),
            '-Xcc', '-mthumb',
            '-Xcc', '-ffreestanding',
            '-Xcc', '-I{}/include'.format(ARM_SYSROOT),
            '-Xcc', '-I{}'.format(os.path.join(ctx.path.abspath(), 'include')),
            '-I', os.path.join(ctx.path.abspath(), 'include'),
            '-wmo', '-O',
            '-Xfrontend', '-disable-reflection-metadata',
            '-Xfrontend', '-disable-stack-protector',
            '-module-name', 'PebbleApp',
            '-emit-objc-header-path', swift_header,
            '-c', '-o', swift_obj,
        ]
        if fpu:
            swift_flags += ['-Xcc', '-mfpu={}'.format(fpu),
                            '-Xcc', '-mfloat-abi={}'.format(float_abi)]

        swift_sources = [n.abspath() for n in ctx.path.ant_glob('src/swift/**/*.swift')]
        cmd = swift_flags + swift_sources

        ctx.to_log('Compiling Swift for {}...\n'.format(platform))
        ret = subprocess.run(cmd)
        if ret.returncode != 0:
            ctx.fatal('Swift compilation failed for platform: {}'.format(platform))

        app_elf = '{}/pebble-app.elf'.format(build_dir)
        swift_o_node = build_node.make_node('swift_app.o')
        ctx.pbl_build(
            source=ctx.path.ant_glob('src/c/**/*.c') + [swift_o_node],
            target=app_elf,
            bin_type='app',
        )
        binaries.append({'platform': platform, 'app_elf': app_elf})

    ctx.env = cached_env
    ctx.set_group('bundle')
    ctx.pbl_bundle(
        binaries=binaries,
        js=ctx.path.ant_glob(['src/pkjs/**/*.js']),
        js_entry_file='src/pkjs/index.js',
    )
