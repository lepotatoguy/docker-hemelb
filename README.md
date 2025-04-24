# docker-hemelb
Docker container with HemeLB installed. It offers a graphical session
accessible from your browser (via a noVNC client) so that you can run
the HemeLB setup tool.

Build the container with: `docker build -t hemelb .`

Launch the container with: `docker run -i -t -p 6080:80 -v <path_to_your_data>:/data  hemelb`,
where `<path_to_your_data>` is the folder in the host system that you want to mount as `/data` in the container.

The path of your data should include:
- .stl file
- .xml file
- .gmy file (if any)
- .pr2 file (if any)

Example command: 
`docker run -it -p 6080:80 -v /home/joyanta/hemelb/hemelb-experiments/large_cylinder_default/input:/data hemelb`

When running the container via boot2docker (e.g. OS X, Windows): Connect with
your browser to the boot2docker VM on port 6080, i.e. `http://192.168.99.100:6080`

When running the container natively (e.g. GNU/Linux): Connect with
your browser to the localhost on port 6080, i.e. `http://localhost:6080`
