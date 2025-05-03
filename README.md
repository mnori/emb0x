# this is emb0x
emb0x is me trying to make a free open source Soundcloud alternative. just getting started right now.

# architecture

what follows is a description of the Docker containers I've put together so far.
- `webapp`
  - this holds the web server, that uses a .net c# based backend. `webapp` inserts into the `database` when a file is uploaded.
- `database`
  - holds the `database` engine which at the moment will always be mysql
- `import-manager`
  - here there is a daemon that handles imported files such as .zip or individual tracks that are uploaded from `webapp`. It receives tasks from the `database` that are placed there by `webapp`. like `webapp`, the `import-manager` is written in c#.
- `minio` drop in replacement for AWS S3, for local testing. After tracks have been processed, they are stored here.

# run it on your own b0x
this requires docker to be installed first

in a folder you've chosen to put emb0x:
```
git clone https://github.com/mnori/emb0x.git
cd emb0x
docker-compose up --build
```

you probably need to run dotnet migrations when it's the first time, see the bin folder for hints

or just give me the author (@mnori) a shout, if you have any queries

visit http://localhost:5000/Upload when the docker containers look happy

have fun!

*confidentcats4eva*
