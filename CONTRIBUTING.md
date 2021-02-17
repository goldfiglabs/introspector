# Developer Certificate of Origin + License

All contributions are subject to the following developer certificate of origin and license terms: https://developercertificate.org/ This Source Code Form is subject to the terms of the Mozilla Public License, v.2.0. If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Gold Fig development environment

git clone https://github.com/goldfiglabs/introspector.git

## Prerequisites

Mac

```
brew update
brew doctor
brew install postgresql
brew services start postgresql
brew install pyenv
brew install pipenv
aws configure
```

Linux

```
sudo apt-get update
sudo apt-get install postgresql
pip install pipenv
pyenv install 3.7.7
aws configure
```

## Getting started

Bootstrap in to correct environment. Also be sure to rerun these any time your pull down updates.

```
pipenv install
pipenv shell
```

## Short-circuit imports to reset or remap

```
$ ./introspector.py account aws remap -i <import_job_id>
$ ./introspector.py debug reset -p <account_provider_id>
```
