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

doc-revision() {
    local url="$1"
    local etag=$(couch-head "$url" | grep ETag)
    echo "${etag/ETag: /}"
}

couch-get() {
    local url="$1"
    curl -X GET "$url"
}

couch-push(){
    local http_type="$2"
    local url="$1"
    local file="$3"
    echo curl -X "$http_type" "$url" -H "Content-Type: application/json" -d @"$file"
    curl -X "$http_type" "$url" -H "Content-Type: application/json" -d @"$file"
}

couch-post() {
    local url="$1"
    local json="$2"
    couch-push "$url" POST "$json"
}

couch-put() {
    local url="$1"
    local json="$2"
    couch-push "$url" PUT "$json"
}

couch-upload-file() {
    local db_url="$1"
    local file_path="$2"
    local mime="$3"
    local rev=$(doc-revision "$db_ur"l)
    rev=$(doc-revision "$db_url")
    echo "rev = $rev"
    local rev_no_quotes=$(trim "${rev//\"}")
    echo "file name = $file_path"
    local attachment_url="${db_url}/${file_path}?rev=${rev_no_quotes}"
    echo "$attachment_url"
    curl -X PUT "${attachment_url}" -H "Content-Type: ${mime}" --data-binary "@${file_path}"
}

couch-upload-json() {
    local db_url="$1"
    local json="$2"
    local rev=$(doc-revision "$db_ur"l)
    rev=$(doc-revision "$db_url")
    echo "rev = $rev"
    local rev_no_quotes=$(trim "${rev//\"}")
    local attachment_url="${db_url}/${file_path}?rev=${rev_no_quotes}"
    echo "$attachment_url"
    curl -X PUT "${attachment_url}" -H "Content-Type: ${mime}" "${json}"
}

couch-upload-dir() {
    local url="$1"
    local upload_dir="$2"
    cd "$upload_dir"
    find . -type f | while read file; do 
        local file_rel_path="${file:2}"
        local mimetype=$(xdg-mime query filetype "$file_rel_path")
        couch-upload-file "$url" "$file_rel_path" "$mimetype"
    done
    cd -
}

couch-upload-dir-bulk() {
    local url="$1"
    local upload_dir="$2"
    local file_dump="$3"
    cd "$upload_dir"
    doc=$(couch-get "$url")
    #echo "$doc" | underscore print --color

    echo {'"'_attachments'"' : { >> "$file_dump"
    find . -type f | while read file; do 
        local mime_type=$(xdg-mime query filetype "$file")
        local file_base64=$(base64 -w 0 "$file")
        
        echo \
            '"'"${file:2}"'"' : \
            {'"contet_type"' : '"'"$mime_type"'"' \
            ,'"data"' : '"'"$file_base64"'"' } , \
         >> "$file_dump"
    done
    echo }} >> "$file_dump"

#working
#    new_attachments=$(cat "$file_dump")
#    cat "$file_dump"| underscore print --color
#    echo "$new_attachments" | underscore print --color 

# not working
#    echo "$new_attachments" | underscore extend "$doc" |  underscore print --color 

    cd -
}
