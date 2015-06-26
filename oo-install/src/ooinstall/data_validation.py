import re
import os


def is_valid_hostname(hostname):
    """Basic hostname validation; does the heavy lifting for
    validate_hostnames
    """
    print hostname
    if not hostname or len(hostname) > 255:
        return False
    if hostname[-1] == ".":
        # strip exactly one dot from the right, if present
        hostname = hostname[:-1]
    allowed = re.compile("(?!-)[A-Z\d-]{1,63}(?<!-)$", re.IGNORECASE)
    return all(allowed.match(x) for x in hostname.split("."))


def validate_ansible_dir(path):
    """Checks to see if the path is set and that it exists and is a
    directory. Could be smarter, but probably shouldn't be
    """
    result, err = True, None
    if not path:
        result, err = False, "An ansible path must be provided"
    elif not os.path.isdir(path):
        result, err = False, "Ansible path \"{}\" doesn't exist".format(path)
    return result, err


def validate_hostnames(hosts):
    """Run is_valid_hostname over a list of hosts, returns `True, None` if
    all hostnames validate. If one or more hostnames fail validation,
    it returns `False, message` where `message` lists the failed
    hostnames
    """
    message = """
The following hostname(s) are invalid: {}
"""
    result, err = True, None
    invalid_hostnames = []
    for hostname in hosts:
        if not is_valid_hostname(hostname):
            invalid_hostnames.append(hostname)
    if invalid_hostnames:
        result, err = False, message.format(', '.join(invalid_hostnames))
    return result, err
