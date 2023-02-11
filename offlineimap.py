import os
import subprocess

def get_access_token(account):
    my_dir = os.path.dirname(os.path.abspath(__file__))
    return subprocess.check_output((
        os.path.join(my_dir, "oauth2tool.sh"), account))

def get_client_id(account):
    return subprocess.check_output(("pass", "%s/GmailAPI/CID" % account))

def get_client_secret(account):
    return subprocess.check_output(("pass", "%s/GmailAPI/CS" % account))
