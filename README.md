# welcome to emb0x
emb0x is me trying to make a free open source Soundcloud alternative. just getting started right now.

# architecture

- webapp
  - this holds the web server, that uses a .net c# based backend
- database
  - holds the database engine which at the moment will always be mysql
- import-manager
  - here there is a daemon that handles imported files such as .zip or individual tracks that are uploaded from the web server

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
