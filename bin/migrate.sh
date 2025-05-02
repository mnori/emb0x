#!/bin/bash
cd ../
ConnectionStrings__Emb0xDatabaseContext="Server=localhost;Database=emb0x;Port=3306;User=root;Password=confidentcats4eva;allowPublicKeyRetrieval=true;SslMode=None;" \
dotnet ef database update -p SharedLibrary -s webapp
