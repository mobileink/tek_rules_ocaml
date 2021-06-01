load("//ocaml:providers.bzl",
     "CompilationModeSettingProvider",
     "OcamlSDK")
load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

## obtaining CC toolchain:  https://github.com/bazelbuild/bazel/issues/7260

###################################################################
def ocaml_register_toolchains(installation = None, noocaml = None):

    native.register_toolchains("@ocaml//toolchain:ocaml_macos")
    native.register_toolchains("@ocaml//toolchain:ocaml_linux")

#########################
def _ocaml_sdk_impl(ctx):
    return [OcamlSDK(path=ctx.attr.path)]

## We use a trick to obtain the absolute path of the sdk, which we
## need to set the PATH env var for the compilers. This rule is only
## used in the BUILD file that we generate, parameterized by the path
## at load time (which we can do from within a repository_rule).
## So rules that need the sdk path can get it from "@ocaml_sdk//:path"
ocaml_sdkpath = rule(
    implementation = _ocaml_sdk_impl,
    attrs = {
        "path": attr.string(
            mandatory = True
        ),
    },
)

################################################################
_ocaml_tools_attrs = {
    "path": attr.string(),
    "sdk_home": attr.string(),
    "opam_root": attr.string(),
    "linkmode": attr.string(
        doc = "Default link mode: 'static' or 'dynamic'"
        # default = "static"
    ),
    "assembler": attr.string(
        doc = "Path to the 'as' executable"
    ),
    ## Hack, until we figure out how to use platforms to support clang on linux
    "_cc_toolchain": attr.label(
        default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
    ),

    ## FIXME: these should be provided by the toolchain definition?
    "_ocamlc": attr.label(
        default = Label("@ocaml//tools:ocamlc"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_ocamlc_opt": attr.label(
        default = Label("@ocaml//tools:ocamlc.opt"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_ocamlopt": attr.label(
        default = Label("@ocaml//tools:ocamlopt"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_ocamlopt_opt": attr.label(
        default = Label("@ocaml//tools:ocamlopt.opt"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_ocamllex": attr.label(
        default = Label("@ocaml//tools:ocamllex"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_ocamlyacc": attr.label(
        default = Label("@ocaml//tools:ocamlyacc"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_copts": attr.string_list(
        default = [
            # "-g", # Record debugging information for exception backtrace
            # "-strict-formats", # Reject invalid formats accepted by legacy implementationsg
            # "-short-paths", # use shortest path printing type names in inferred interfaces, error, warning msgs
            # "-strict-sequence", # Left-hand part of a sequence must have type unit
            # "-keep-locs",  #  Keep locations in .cmi files (default)
            # "-no-alias-deps",  #  Do not record dependencies for module aliases
            # "-opaque" # Does not generate cross-module optimization information (reduces necessary recompilation on module change)
    ]
    ),
    "_ocamlfind": attr.label(
        default = Label("@ocaml//tools:ocamlfind"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    # "_ocamlbuild": attr.label(
    #     default = Label("@ocaml//:ocamlbuild"),
    #     executable = True,
    #     allow_single_file = True,
    #     cfg = "host",
    # ),
    "_ocamldep": attr.label(
        default = Label("@ocaml//:ocamldep"),
        executable = True,
        allow_single_file = True,
        cfg = "host",
    ),
    "_dllpath": attr.label(
        ## FIXME default = Label("@opam//pkg:stublibs"),
    )
    # "_opam": attr.label(
    #   default = Label("@opam//:opam"),
    #   executable = True,
    #   allow_single_file = True,
    #   # allow_files = True,
    #       cfg = "host",
    # ),
}

def _ocaml_toolchain_impl(ctx):
    if not ctx.attr.linkmode in ["static", "dynamic"]:
        fail("Bad value '{actual}' for attrib 'link'. Allowed values: 'static', 'dynamic' (in rule: ocaml_toolchain(name=\"{n}\"), build file: \"{bf}\", workspace: \"{ws}\"".format(
            ws = ctx.workspace_name,
            bf = ctx.build_file_path,
            n = ctx.label.name,
            actual = ctx.attr.linkmode
        )
             )
    # if not ctx.attr.mode in ["native", "bytecode"]:
    #     fail("Bad value '{actual}' for attrib 'mode'. Allowed values: 'native', 'bytecode' (in rule: ocaml_toolchain(name=\"{n}\"), build file: \"{bf}\", workspace: \"{ws}\"".format(
    #         ws = ctx.workspace_name,
    #         bf = ctx.build_file_path,
    #         n = ctx.label.name,
    #         actual = ctx.attr.mode
    #     )
    #          )
    # mode = ctx.attr.mode[CompilationModeSettingProvider].value

    return [platform_common.ToolchainInfo(
        # Public fields
        name = ctx.label.name,
        path       = ctx.attr.path,
        sdk_home   = ctx.attr.sdk_home,
        opam_root  = ctx.attr.opam_root,
        linkmode       = ctx.attr.linkmode,
        # opam       = ctx.attr._opam.files.to_list()[0],
        # mode       = ctx.attr.mode,
        # compiler   = ctx.attr._compiler.files.to_list()[0],
        ocamlc     = ctx.attr._ocamlc.files.to_list()[0],
        ocamlc_opt = ctx.attr._ocamlc_opt.files.to_list()[0],
        ocamlopt   = ctx.attr._ocamlopt.files.to_list()[0],
        ocamlopt_opt = ctx.attr._ocamlopt_opt.files.to_list()[0],
        ocamllex   = ctx.attr._ocamllex.files.to_list()[0],
        ocamlyacc  = ctx.attr._ocamlyacc.files.to_list()[0],
        assembler = ctx.attr.assembler,
        cc_toolchain = find_cpp_toolchain(ctx),
        copts       = ctx.attr._copts,
        # ocamlbuild = ctx.attr._ocamlbuild.files.to_list()[0],
        ocamlfind  = ctx.attr._ocamlfind.files.to_list()[0],
        # ocamldep   = ctx.attr._ocamldep.files.to_list()[0],
        # objext     = ".cmx" if mode == "native" else ".cmo",
        # archext    = ".cmxa" if mode == "native" else ".cma",
        # dllpath    = ctx.path(Label("@opam//pkg:stublibs"))
    )]

ocaml_toolchain = rule(
  _ocaml_toolchain_impl,
  attrs = _ocaml_tools_attrs,
  doc = "Defines a Ocaml toolchain based on an SDK",
  provides = [platform_common.ToolchainInfo],
  fragments = ["cpp"],
)
