# this is emb0x
emb0x is a project that aims to produce a good quality free and open source Soundcloud alternative. a neglected market imo. just getting started right now.

# architecture

what follows is a description of the Docker containers I've put together so far.
- `webapp`
  - this holds the web server, that uses a .net c# based backend. `webapp` inserts into the `database` when a file is uploaded.
- `database`
  - holds the `database` engine which at the moment will always be mysql. future versions might support something scalable like cockroachdb instead of mysql if you want. it seems pretty easy to swap the database engine when you use the .net framework.
- `import-manager`
  - here there is a daemon that handles imported files such as .zip or individual tracks that are uploaded from `webapp`. It receives tasks from the `database` that are placed there by `webapp`. like `webapp`, the `import-manager` is written in c#. some code such as the DB stuff is shared between `webapp` and `import-manager`
- `minio` is a drop in replacement for AWS S3, for local testing. after tracks have been processed, they are stored here, in flac format, ready to be played inside the browser. when you deploy on aws for real, you'll use aws's s3 instead.

# run it on your own b0x
this requires docker to be installed first. get Docker Desktop imo. don't waste your life scratching your head over too much docker on the command line when you can use that juicy ui and quickly have a nice nosy at the file structure and logs etc.

in a folder you've chosen to put emb0x (i like to git clone repos into the same `~/dev` folder):
```
git clone https://github.com/mnori/emb0x.git
cd emb0x
docker-compose up --build
```

i run my commands on windows with git bash

you need to run dotnet migrations when it's the first time - `./migrate.sh` in the `bin/` folder

# useful addresses
- visit http://localhost:5000/Upload when the docker containers look happy to try uploading a file. The upload system accepts compressed files containing multiple tracks, or individual audio files, any mainstream archive format and any audio format that is regularly used too.
- the database container listens on localhost:3306. username "admin" and password "confidentcats4eva". you can use whatever you want for your mysql database client, my favourite one is DBeaver, which works great just has a silly name
- the minio module (analogous to S3 but without needing AWS) can be accessed with this kind of URL: http://localhost:9000/audio-files/a20e3351-b67c-40d7-b49a-a6d0523cf18c.audio - replace the UUID of the filename with the one you get presented with after uploading a file.

# closing remarks

give me the author (@mnori) a shout if you have any queries or if you are interested in contributing even. if you are brave enough to try adding something to this project, best check with me first just to make sure you're not doing the same shit that someone else is already doing innit

further up and further in

have fun!

*confidentcats4eva*
