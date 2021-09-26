class MulticastConfig:
    def __init__(self, *, useMulticast, multicastGroupNodes, multicastNetworkRows, multicastNetworkCols, multicastFifoDepth):

        self.useMulticast = useMulticast
        self.multicastGroupNodes = multicastGroupNodes
        self.multicastNetworkRows = multicastNetworkRows
        self.multicastNetworkCols = multicastNetworkCols
        self.multicastFifoDepth = multicastFifoDepth

    '''
    Generate VHDL package containing multicast configuration
    '''
    def write_header_file(self, *, hdlFolder, fileName="multicast_defs.vhd"):
        from jinja2 import Environment, FileSystemLoader
        import os

        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)
        fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))
        env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True)

        template = env.get_template('multicast_defs.vhd')
        output = template.render(multicastConfig=self)

        # Write output to file
        headerFileName = '{directory}/../{hdlFolder}/src/{fileName}'.format(directory=scriptDirectory, hdlFolder=hdlFolder, fileName=fileName)
        headerFile = open(headerFileName, 'w')
        headerFile.write(output)
        headerFile.close()
