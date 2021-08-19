class Firmware:
    def __init__(self, binaryName, memSize):
        self.binaryName = binaryName
        self.memSize = memSize

    '''
    Generate assembly for firmware
    '''
    def write_assembly_file(self, firmwareFolder):
        from jinja2 import Environment, FileSystemLoader
        import os

        scriptLocation = os.path.realpath(__file__)
        scriptDirectory = os.path.dirname(scriptLocation)
        fileLoader = FileSystemLoader('{directory}/templates'.format(directory=scriptDirectory))

        env = Environment(loader=fileLoader, trim_blocks=True, lstrip_blocks=True, keep_trailing_newline=True)

        template = env.get_template('firmware.S')
        output = template.render(firmware=self)

        # Strip the extension from the binaryName and add .S
        fileName = os.path.splitext(self.binaryName)[0] + '.S'

        # Write output to file
        ldsFileName = '{directory}/../firmware/{firmwareFolder}/{fileName}'.format(directory=scriptDirectory, firmwareFolder=firmwareFolder, fileName=fileName)
        ldsFile = open(ldsFileName, 'w')
        ldsFile.write(output)
        ldsFile.close()
