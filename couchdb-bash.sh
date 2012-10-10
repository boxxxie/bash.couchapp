#!/bin/bash

  # These functions require underscore-cli (npm install -g underscore-cli)
  # a CouchDB instance

host="$1"

couch-get() {
    db="$1"
    url="$host/$db"
    echo curl -sX GET "$url"
    curl -sX GET "$url"
}

couch-head(){
    db="$1"
    url="$host/$db"
    echo curl -sI HEAD "$url"
    curl -sI HEAD "$url"
}

couch-revision(){
    db="$1"
    url="$host/$db"
    etag_kv=`curl -sI "$url" | grep ETag`
    echo ${etag_kv:5}
}

couch-push(){
    http="$1"
    db="$2"
    doc="$3"
    url="$host/$db"
    echo curl -X "$http" "$url" -H "'""Content-Type: application/json""'" -d @"$doc"
    curl -X "$http" "$url" -H "'""Content-Type: application/json""'" -d @"$doc"
}

couch-post() {
    db="$1"
    doc="$2"
    couch-push POST "$db" "$doc"
}

couch-put() {
    db="$1"
    doc="$2"
    couch-push PUT "$db" "$doc"
}

couch-upload() {
    db="$1"
    file="$2"
#    couch_response=`$(couch-get "$db")`
#    echo "response = $couch_response"
#    echo underscore -d "$couch_response" extract _rev
#    rev=$(underscore -d "$couch_response" extract _rev)
    rev=`couch-revision "$db"`
    echo "rev = $rev"
    echo "rev w/o quotes = ${rev//\"}"
    safe_file=${file// /-}
    echo "file name = $safe_file"
    url="$host/$db/$safe_file?rev=${rev//\"}"
    echo "$url"
    #echo curl -sX PUT "$url" -H "Content-Type: $3" --data-binary @"$file"
    curl -sX PUT "$url" -H "Content-Type: $3" --data-binary @"$file"
}

#use: ./couchdb-bash.sh http://localhost:5984 db/doc doc.json 'application/json'
#use: ./couchdb-bash.sh http://localhost:5984 db/doct test/doc.json 'application/json'
#couch-upload "$testdoc" "$3" "$4"

dir_to_upload="$2"
db="$3"

#echo `couch-head "$db"`
#echo `couch-revision "$db"`

#exit 0

cd "$dir_to_upload"
file_index=0
find .  | while read file_long_name; do
    #echo "$file"
    file=${file_long_name:2}
    blobs[file_index]=`base64 <"$file"`
    md5s[file_index]=`md5deep <"$file"`
    file_index=$[file_index+1]
    couch-upload "$db" "$file"
done
cd -
#./couchdb-bash.sh http://localhost:5984 test/processed_doc/attachments/ test/test 
