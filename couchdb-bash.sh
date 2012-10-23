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
    curl -X PUT "${attachment_url}" -H "Content-Type: ${mime}" --data-binary "'" "@${file_path}" "'"
}

couch-upload-json-file() {
    local db_url="$1"
    local json="$2"
    local rev=$(doc-revision "$db_url")
    rev=$(doc-revision "$db_url")
    echo "rev = $rev"
    local rev_no_quotes=$(trim "${rev//\"}")
    local attachment_url="${db_url}/${file_path}?rev=${rev_no_quotes}"
    curl -v -X PUT "${attachment_url}" -H "Content-Type: application/json" --data-binary  "@${json}"
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

base64_attachment() {
    local file="$1";
    local file_name="${file:2}";
    local mime_type=$(xdg-mime query filetype "$file");
    local file_base64=$(base64 -w 0 "$file");
    echo '"'"$file_name"'"' : \
        {'"content_type"' : '"'"$mime_type"'"' \
        ,'"data"' : '"'"$file_base64"'"' }
}

md5_maker() {
    local file="$1";
    local file_name="${file:2}";
    local md5=$(echo "$file" | md5deep) ;
    echo '"'"$file_name"'"' : { '"md5"' : '"'"$md5"'"' }
}

dir-to-couchdb-json() {
    local url="$1"
    local upload_dir="$2"
    local file_dump="$3"
    cd "$upload_dir"
    doc=$(couch-get "$url")

    #get an array of all of the files we are going to upload to couchdb
    #mapfile -t files < <(find . -type f) ;
    
#attachments removed
    local doc_no_attachments=$(underscore extend --data "$doc" '{"_attachments": undefined}')
#attachments extracted
    local original_attachments=$(echo "$doc" | underscore extract _attachments)

    echo
    echo original_attachments    
    echo "$original_attachments"

    local attachment_md5s=$(underscore pluck --data "$original_attachments" md5)
    echo
    echo attachment_md5s    
    echo "$attachment_md5s"

    local original_attachments_trimmed_back="${original_attachments%'}'}"
    local original_attachments_trimmed="${original_attachments_trimmed_back#'{'}"

    doc_no_attachments_len="${doc_no_attachments}"
    doc_no_attachments_beginning="${doc_no_attachments%'}'} ,"

    echo "$doc_no_attachments_beginning" >> "$file_dump"


#### md5 processing #####
    
    echo '"'"attachments_md5s"'"' ': {' >> "$file_dump" ;

    local first_md5='';
    find . -type f | {
        while read file ; do          
            if [ "$first_md5" ] ;
            then
                local md5=$(md5_maker "$file") ;
                echo "$md5" ',' >> "$file_dump" ;
            else
                first_md5=$(md5_maker "$file") ;
            fi
        done
        echo "$first_md5" '},' >> "$file_dump"
    }
### attachment processing ####

    echo '"'"_attachments"'"' ': {' >> "$file_dump" ;
    echo "$original_attachments_trimmed" ','  >> "$file_dump" ;

    local first_attachment='';
    find . -type f | {
        while read file ; do          
            if [ "$first_attachment" ] ;
            then
                local attachment=$(base64_attachment "$file") ;
                echo "$attachment" ',' >> "$file_dump" ;
            else
                first_attachment=$(base64_attachment "$file") ;
            fi
        done
        echo "$first_attachment" '}' >> "$file_dump"
    }
    echo '}' >> "$file_dump" ;
    cd -
}

