Not ready for release. 

trial at your own err

need love2d, and 



a general research project for and inspired by:
https://github.com/notnullgames/pakemon-demos

Planet asset from, really fun stuff! 
https://deep-fold.itch.io/pixel-planet-generator


```
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")

and for the metasploit module:
 
local mp = require("MessagePack")

```

there is also an optional sql-dep that is burried, but that function needs updating anyhow.

if you're not running it on the test net... well somethings are "hard coded" via variables to the docker test-net right now.

you will need bettercap running on the testnet as well as metasploit avail on port 55552 locally exposed from the test-net


over-reaching goals of the project; our praxis: 

    User Experience (UX): Make sure that the interface is intuitive. Since the project aims to be accessible, the design should guide the user through processes without overwhelming them with information.

    Educational Content: Provide context and educational materials. For example, when a user performs an action, you could offer a brief explanation of what the command does and what the expected outcome is.

    Safety Measures: Since the tool interfaces with powerful frameworks like Metasploit, it's crucial to have safety measures in place to prevent misuse or accidental damage.

    Progressive Difficulty: Start with simple tasks and gradually introduce more complex scenarios. This scaffolding helps users build confidence and knowledge as they progress.

    Feedback System: Implement a feedback mechanism that informs users of the success or failure of their actions, what went wrong if there was an error, and how to correct it.




    Community and Support: Develop a community support system where users can share experiences, help each other out, and contribute to the project.

    Gamification: Introduce elements like scoring, badges, or levels to motivate users and track their progress.

    Responsibility and Ethics: Teach users about the ethical use of hacking tools and the importance of permission and legality in penetration testing.

```


There is a pretty big warning in that the docker-compose.yaml in aTools, and tools has some nasty bugs to explore so be careful! 
This docker set-up is from the https://github.com/notnullgames/pakemon-demos project



`` `
version: "3.5"

services:
    
    # this gives you a CLI to interrogate
    haxor:
       image: kalilinux/kali-rolling
       tty: true
       networks:
           - pakemon
       ports:
           - 55552:55552

    bettercap:
        image: bettercap/bettercap
        tty: true
        stdin_open: true
        networks:
            - pakemon
        ports:
            - 8080:8080
            - 8081:8081
        volumes:
            - ./pakemon.cap:/app/pakemon.cap
        command: -caplet pakemon

    # these are targets:
    nowasp:
        image: citizenstig/nowasp
        hostname: nowasp
        networks:
            - pakemon
    
    webgoat:
        image: webgoat/webgoat-7.1
        hostname: webgoat
        networks:
            - pakemon
    
    dvwa:
        image: citizenstig/dvwa
        hostname: dvwa
        networks:
            - pakemon
    
    securityshepherd:
        image: ismisepaul/securityshepherd
        hostname: securityshepherd
        networks:
            - pakemon

    vaas-cve-2014-0160:
        image: hmlio/vaas-cve-2014-0160
        hostname: vaas-cve-2014-0160
        networks:
            - pakemon
    cve-2017-7494:
        image: vulnerables/cve-2017-7494
        hostname: cve-2017-7494
        networks:
            - pakemon
    vaas-cve-2014-6271:
        image: hmlio/vaas-cve-2014-6271
        hostname: vaas-cve-2014-6271
        networks:
            - pakemon

# careful, this is a war-zone :)
networks:
    pakemon:
        name: pakemon
```



