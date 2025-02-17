# PaperMC-crossplay-scripts
What I use for maintaining "crossplay-enabled" Minecraft servers. This documents serves as a kind of "layperson's/-admin's intro to the problem and the solution" (and for my own memo).

## What is the deal with "crossplay"?
There are, as of 2024, **two** competing and mutually incompatible variants of Minecraft: the **Bedrock Edition** (which in MS marketing is called "Minecraft"<sup>TM</sup>) **and** the Java version (aka "Minecraft: Java Edition").

The rough idea is that if you are a _normie_ Windows kid you should use the Bedrock variant and you must pay for a Realm (=a personal persistet world instance) if you wanna play together with your friends; on the flipside if you are a _weirdo_ you probably want to do things like tweak the JVM manually and thus run the Java variant, which remains feature-wise closer to the "pre-Microsoft" versions of Minecraft.

## YEah yeah so what's the deal, why not pay for your Realm and get on with it?
IF only it was that easy... _"Realms for Java Edition supports cross-platform play between Windows, Linux, and macOS"_ - this is true. **But**, there are other platforms out there, most notably iOS and Nintendo Switch versions - both "Bedrock". These are more or less treated as 3rd grade citizens that deserve only to play with their kin. 

A traditional family might look like this, platform-wise:

| Member | Platform       |
|--------|----------------|
| Mother | iOS(Bedrock)   |
| Father | macOS(Java)    |
| Child1 | Android(Java)  |
| Child2 | Switch(Bedrock)|
| Friend1| PS4(Bedrockish)|

Basically you CAN'T just go ahead and play together out-of-the-box. 

## The solution
Thanks to years of toil by lovely hackers around the world, we have wonderful open-source software to the rescue! I prefer to use a high-performance Minecraft server called [PaperMC](https://papermc.io/) which runs on the JVM, which means I can run it on Linux. It uses a plugin-mechanism called "Spigot" (yeah,_ I know_) which in turn allows for the use of a couple of server plugins that TRANSLATE and NORMALIZE the differences across the game editions: those plugin projects are "[Geyser](https://geysermc.org/wiki/geyser/)" for game-features and "[Floodgate](https://geysermc.org/wiki/floodgate/)" for authentication purposes. In some situations, "[ViaVersion](https://viaversion.com/)" (protocol translation) is also desirable. 

<sub>I also include [Bluemap](https://bluemap.bluecolored.de/) which provides an awesome Google StreetView-like experience in the web browser but it's completely unrelated to crossplay.</sub>

For _${reasons}_, the java entrypoint is always `server.jar` which is a symlink to the most recent PaperMC JAR. The plugin JAR:s on the other hand are meant to have only active version each, but the script keeps older versions around just in case, with a `.jar_old` file extension so they don't get ambiguously loaded.

## The script
Now each time the official Minecraft game receives an update, one-to-four .jar:s need to be updated and named on your server. This quickly becomes a major HASSLE when all you wanna do is just _play_, not be a full-time Minecraft Admin (there's an `r/admincraft` [subreddit](https://www.reddit.com/r/admincraft/)). The `download-latest-papermc-components.sh` is not meant to be an end-all-be-all server manager, just a helper script to find, download and name the latest versions of each corresponding JAR file. Please fork it and adapt it to your own needs. 

I've been using it together with the [Lodestone](https://lodestone.cc/) self-hosted instance manager. YMMV.

# Doesn't this exist already?!
Yeah, sure, but either unmaintained or overengineered, or in GUI form, in hosted/SAAS-form, or with more of a client-side "Gamer" focus on Mods and Resource Packs (=irrelevant for this usecase). 

If you want an very _nice_ and _interactive_ plugin updater tool then go check out [pluGET.py](https://github.com/Neocky/pluGET). But you'll have to manage Python dependencies instead 😉
