#!/bin/bash

  # These functions require a CouchDB instance, xdg-mime, curl, 

trim() {
    # Determine if 'extglob' is currently on.
    local extglobWasOff=1
    shopt extglob >/dev/null && extglobWasOff=0 
    (( extglobWasOff )) && shopt -s extglob # Turn 'extglob' on, if currently turned off.
    # Trim leading and trailing whitespace
    local var=$1
    var=${var##+([[:space:]])}
    var=${var%%+([[:space:]])}
    (( extglobWasOff )) && shopt -u extglob # If 'extglob' was off before, turn it back off.
    echo -n "$var"  # Output trimmed string.
}

rawurldecode() {

  # This is perhaps a risky gambit, but since all escape characters must be
  # encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
  # will decode hex for us

    printf -v REPLY '%b' "${1//%/\\x}" # You can either set a return variable (FASTER)

    echo "${REPLY}"  #+or echo the result (EASIER)... or both... :p
}

couch-head() {
    local url="$1"
    curl -I "$url"
}

doc-rev() {
    local url="$1"
    local etag=$(couch-head "$url" | grep ETag)
    echo "${etag/ETag: /}"
}

trim () {
    local url="$1"
    curl -X GET "$url"

couch_get() {
}

couch_head() {
    db="$1"
    url="$host/$db"
    echo curl -sI  "$url"
    curl -sI  "$url"
}

couch_revision() {
    db="$1";
    url="$host/$db";
    etag_kv=`curl -sI "$url" | grep "ETag"`;
    return=$(trim ${etag_kv:5});
    echo "$return";
}

couch_push() {
    local http_type="$2"
    local url="$1"
    local file="$3"
    echo curl -X "$http_type" "$url" -H "Content-Type: application/json" -d @"$file"
    curl -X "$http_type" "$url" -H "Content-Type: application/json" -d @"$file"
}

couch_post() {
    local url="$1"
    local file="$2"
    couch-push "$url" POST "$file"
}

couch_put() {
    local url="$1"
    local file="$2"
    couch-push "$url" PUT "$file"
}

couch_upload() {
    local db_url="$1"
    local file_path="$2"
    local mime="$3"
    local rev=$(doc-rev $db_url)
    #rev_clean=$(trim "$rev")
    rev=$(couch_revision "$db")
    echo "rev = $rev"
    local rev_no_quotes=$(trim "${rev//\"}")
    echo "file name = $file_path"
    local attachment_url="${db_url}/${file_path}?rev=${rev_no_quotes}"
    echo "$attachment_url"
    curl -X PUT "${attachment_url}" -H "Content-Type: ${mime}" --data-binary "@${file_path}"
    #echo curl -sX PUT "$url" -H "Content-Type: $3" --data-binary @"$file"
}

couch-upload-dir() {
    local url="$1"
    local upload_dir="$2"
    cd "$upload_dir"
    find .  | while read file; do 
        if [ -f "$file" ]
        then
            local file_rel_path="${file:2}";
            local mimetype=$(xdg-mime query filetype "$file_rel_path")
            couch-upload "$url" "$file_rel_path" "$mimetype"
        fi
    done
    cd -
}

couch-upload-dir-bulk() {
    local url="$1"
    local upload_dir="$2"
    local file_dump="$3"
    cd "$upload_dir"
    find .  | while read file; do 
        if [ -f "$file" ]
        then
            echo "${file:2}" >> "$file_dump"
            echo "${file:2}" >> "$file_dump"
            echo >> "$file_dump"
            xdg-mime query filetype "$file" >> "$file_dump"
            echo >> "$file_dump"
            base64 "$file" >> "$file_dump"
            echo >> "$file_dump"
            exit 0
        fi
    done
echo $file_index
    cd -
}

#bulk="$3"
#rm "$bulk"
#touch "$bulk"
#couch-upload-dir-bulk "$1" "$2" "$bulk"

#echo done!
