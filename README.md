# this is emb0x
emb0x is a project that aims to produce a good quality free and open source Soundcloud alternative. a neglected market imo. just getting started right now.

# architecture

what follows is a description of the Docker containers I've put together so far.
- `webapp`
  - this holds the web server, that uses a .net c# based backend. when files are uploaded, `webapp` inserts into the `database` and places the uploaded file in a shared volume. the web server is also responsible for allowing the uploaded track to be browsed and played after it has been through the `import-manager`
- `database`
  - holds the `database` engine which at the moment will always be mysql. future versions might support something scalable like cockroachdb instead of mysql if you want. but i doubt you'd ever really need it unless you're taylor swift telling people about your music site after performing on tv. i used to work for a company where we had to deal with big spikes of traffic from the tv. that's the situation where you scale. it seems pretty easy to swap the database engine when you use the .net framework anyway. i wasted 6 years of my life on java/spring/hibernate which is absolute shite in comparison. fuck everything about hibernate trust me
- `import-manager`
  - here there is a daemon that handles imported files such as .zip or individual tracks that are uploaded from `webapp`. It receives tasks from the `database` that are placed there by `webapp`. like `webapp`, the `import-manager` is written in c#. compressed files are unpacked and the tracks within are processed and individually added. each track gets a row in the database and gets turned into a .flac file. pretty much every reasonably well known audio format is supported, using the already very capable free software `ffmpeg` to handle the conversion process. the .flac then gets placed in dedicated storage, either `minio` locally or `s3` in production. some code such as the DB stuff is shared between `webapp` and `import-manager`, especially anything to do with the database.
- `minio`
  - this container holds a drop in replacement for AWS S3, so you can work locally without paying that wanker bezos anything until you are ready to push your stuff into production. this is the final resting place for processed tracks, ready to be played inside the browser. when you deploy on aws for real, you'll use aws's s3 instead, of course. cos bezos always gets his pound of flesh in the end. massive respect to Luigi my favourite Nintendo character btw for no particular reason.

# run it on your own b0x
this requires docker to be installed first. get Docker Desktop imo. don't waste your life scratching your head over too much docker on the command line when you can live the dream getting where you need to go using the juicy docker ui that makes it effortless to get a nice nosy at the file structure and logs etc.

in a folder you've chosen to put emb0x (i like to git clone repos into the same `~/dev` folder):
```
git clone https://github.com/mnori/emb0x.git
cd emb0x
docker-compose up --build
```
when you run the docker-compose command the whole stack will launch. it will then be accessible in the browser, see the links below for what to use as your url. ctrl-c in the terminal that you launched the whole thing will cause it to try and shut down gracefully.

you need to run dotnet migrations when it's being spawned for the first time - `./migrate.sh` in the `bin/` folder, in order to create the tables

i run my commands on windows with git bash

if you use mac or linux, i am sure you can get it all working on that as well if you are dull enough to have managed to read this far

# AWS deployment (production)

yet to be implemented but expect to reach this side of the project soon and have the first prototype published online in a few week's time. i am thinking about reading up on kubernates and finally dipping my toes in that thing cos i still haven't touched it yet despite working in tech for ages.

# useful addresses to test the thing out with
- visit http://localhost:5000/Upload when the docker containers have all started to try uploading a file. The upload system accepts compressed files containing multiple tracks, or individual audio files, any mainstream archive file type or audio format should be supported. the form has a limit of 1gb though as the web upload element doesn't cope with files that are too big. i'm going to add a new feature that supports ftp uploads for cases when you have an enourmous amount of material to import, like the embers breaks corpus for example, which is well over 500 individual tracks, 60gb total.
- the database container listens on localhost:3306. username "admin" and password "confidentcats4eva". you can use whatever you want for your mysql database client, my favourite one is DBeaver, which works great just has a silly name, try and think of the lovely wholesome beavers from the lion the witch and the wardrobe and not the other thing imo esp not in an office environment
- the minio module (analogous to S3 but without needing AWS) and the processed .flac audio files within can be accessed with this kind of URL: http://localhost:9000/audio-files/a20e3351-b67c-40d7-b49a-a6d0523cf18c.audio - replace the UUID of the filename with the one you get presented with after uploading a file.

# closing remarks

give me the author (@mnori) a shout if you have any queries or if you are interested in contributing even. if you are mad or brave enough to try adding something to this project, best check with me first just to make sure you're not doing the same shit that someone else is already doing innit. i really do welcome other people's contributions though in all seriousness. who knows, if this thing ever gets big, and you've made a stamp on it, it could help you find a nice job etc etc

have fun!

further up and further in

*confidentcats4eva*
