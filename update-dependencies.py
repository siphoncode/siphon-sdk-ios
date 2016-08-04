#!/usr/bin/env python3

from contextlib import contextmanager
import os
import subprocess
from termcolor import colored

from siphon_dependencies import Dependencies

def yn(msg):
    try:
        valid_response = False
        while not valid_response:
            response = input(msg) or 'y'
            if response == 'y' or response == 'Y':
                return True
            elif response == 'n' or response == 'N':
                return False
            else:
                msg = 'Please enter \'y\' or \'n\': '
    except KeyboardInterrupt:
        return False

@contextmanager
def cd(*paths):
    path = os.path.join(*paths)
    old_path = os.getcwd()
    print('[cd: %s]' % path)
    os.chdir(path)
    try:
        yield
    finally:
        print('[cd: %s]' % old_path)
        os.chdir(old_path)

def npm_install(dir):
    # Runs 'npm install' in a given directory
    with cd(dir):
        subprocess.call(['npm', 'install'])

def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__)))
    pkg_dir = os.path.join(root, 'Example')
    pkg_path = os.path.join(pkg_dir, 'package.json')

    print(colored('Fetching latest dependencies...', 'yellow'))
    # TODO Fetch this from the repo
    dependencies = Dependencies('0.5')
    dependencies.update_package_file(pkg_path)

    update_modules = yn(colored('Would you like to update your local ' \
                                'node_modules? [Y/n] ', 'yellow'))
    if update_modules:
        npm_install(pkg_dir)

    print(colored('Warning: If react-native has been updated, you will ' \
          'need to update the Podfile of the appropriate project and ' \
          'install.', 'red'))

if __name__ == '__main__':
    main()
