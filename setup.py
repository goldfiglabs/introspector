import setuptools

with open("README.md", "r") as fh:
  long_description = fh.read()

setuptools.setup(
    name="goldfig",
    version="0.0.1",
    author="Gold Fig Labs",
    author_email="hello@goldfiglabs.com",
    description=
    "A schema and set of tools for using SQL to query cloud infrastructure",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/goldfiglabs/goldfig",
    packages=setuptools.find_packages(),
    package_data={"": ["views/*.sql", "transforms/*.yml", "sample_queries/*.sql"]},
    include_package_data=True,
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MPL 2.0 License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.7',
    install_requires=[
        'botocore>=1.15', 'sqlalchemy>=1.3', 'psycopg2-binary>=2.8',
        'jmespath>=0.9', 'jsonpatch>=1.25', 'google-auth>=1.11',
        'google-api-python-client>=1.7', 'pyyaml>=5.3', 'deepdiff', 'tabulate',
        'jsonschema', 'click'
    ],
    entry_points={'console_scripts': ['gf = goldfig.cli:run_cli']})
