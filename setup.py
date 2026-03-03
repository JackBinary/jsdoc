from setuptools import Extension, setup


def _build_extensions():
    try:
        from Cython.Build import cythonize
    except Exception:
        return []

    extensions = [
        Extension(
            "jsdoc._cython_backend",
            ["jsdoc/_cython_backend.pyx"],
            optional=True,
        )
    ]
    return cythonize(extensions, compiler_directives={"language_level": "3"})


setup(ext_modules=_build_extensions())
