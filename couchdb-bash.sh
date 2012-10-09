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
    couch_response=`$(couch-get "$db")`
    echo "response = $couch_response"
    echo underscore -d "$couch_response" extract _rev
    rev=$(underscore -d "$couch_response" extract _rev)
    echo "rev = $rev"
    echo "rev w/o quotes = ${rev//\"}"
    safe_file=${file// /-}
    echo "file name = $safe_file"
    url="$host/$1/$safe_file?rev=${rev//\"}"
    echo "$url"
    curl -sX PUT "$url" -H "Content-Type: $3" --data-binary @"$file"
}

#use: ./couchdb-bash.sh http://localhost:5984 db/doc doc.json 'application/json'
#use: ./couchdb-bash.sh http://localhost:5984 db/doct test/doc.json 'application/json'
#couch-upload "$testdoc" "$3" "$4"

dir_to_upload="$2"
db="$3"

cd "$dir_to_upload"
find .  | while read file; do 
    echo "$file"; 
    couch-upload "$db" "$file"
done
cd -
#./couchdb-bash.sh http://localhost:5984 test/processed_doc/attachments/ test/test 
