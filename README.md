# this is emb0x
emb0x is a project that aims to produce a good quality free and open source Soundcloud alternative. just getting started right now.

# architecture

what follows is a description of the Docker containers I've put together so far.
- `webapp`
  - this holds the web server, that uses a .net c# based backend. `webapp` inserts into the `database` when a file is uploaded.
- `database`
  - holds the `database` engine which at the moment will always be mysql
- `import-manager`
  - here there is a daemon that handles imported files such as .zip or individual tracks that are uploaded from `webapp`. It receives tasks from the `database` that are placed there by `webapp`. like `webapp`, the `import-manager` is written in c#. some code such as the DB stuff is shared between `webapp` and `import-manager`
- `minio` is a drop in replacement for AWS S3, for local testing. after tracks have been processed, they are stored here. when you deploy on aws for real, you'll use aws's s3 instead.

# run it on your own b0x
this requires docker to be installed first. get Docker Desktop imo. don't waste your life fucking around with too much docker on the command line when you can use that juicy ui and quickly see the file structure and logs etc.

in a folder you've chosen to put emb0x:
```
git clone https://github.com/mnori/emb0x.git
cd emb0x
docker-compose up --build
```

you probably need to run dotnet migrations when it's the first time - `./migrate.sh` in the `bin/` folder

# useful addresses
- visit http://localhost:5000/Upload when the docker containers look happy to try uploading stuff
- the database container listens on localhost:3306. username "admin" and password "confidentcats4eva". you can use whatever you want for your mysql database client, my favourite one is DBeaver, which works great just has a silly name
- the minio module (analogous to S3 but without needing AWS) can be accessed with this kind of URL: http://localhost:9000/audio-files/a20e3351-b67c-40d7-b49a-a6d0523cf18c.upload - replace the UUID of the filename with the one you get presented with after uploading a file.

# closing remarks

give me the author (@mnori) a shout if you have any queries or if you are interested in contributing even

have fun!

*confidentcats4eva*
