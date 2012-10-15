node.couchapp.bash
==================

node couchapp style programs but in bash.

source in couchdb-bash.sh to your script, then you will have available these functions.
most of these functions are a thin wrapper over curl
the functions that upload files are a bit more complicated as they need to get couchdb document revisions before uploading a file.
the 2 functions that are related to uploading directories are supposed to take over for node.couchapp where it failes, such as uploading 20,000 attachments to a document (my use-case).

the couch-upload-dir-bulk function streams a json stucture to a file (currently not being correctly made, as it had a trailing comma) so that an external program can use it to push to a server. i would like to have this all done in bash, but this is to be solved in the future. the json file can get very large as it represents all of the files in the dir (base64).

```
couch-upload-dir-bulk() {
    local url="$1"
    local upload_dir="$2"
    local file_dump="$3"
    ...
}

couch-upload-dir() {
    local url="$1"
    local upload_dir="$2"
    ...
}

couch-upload-file() {
    local db_url="$1"
    local file_path="$2"
    local mime="$3"
    ...
}       

couch-put() {
    local url="$1"
    local json="$2"
    ...
}

couch-put() {
    local url="$1"
    local json="$2"
    ...
}

couch-push(){
    local http_type="$2"
    local url="$1"
    local file="$3"
    ...
}

couch-get() {
    local url="$1"
    ...
}

doc-revision() {
    local url="$1"
    ...
}

couch-head() {
    local url="$1"
    ...
}

```