library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package firmware_config is 

    {% if foxNetwork.foxFirmware != None %}
    constant FOX_FIRMWARE       : string := "{{ foxNetwork.foxFirmware.binaryName }}";
    constant FOX_MEM_SIZE       : integer := {{ foxNetwork.foxFirmware.memSize }};
    {% endif %}

    {% if foxNetwork.resultFirmware != None %}
    constant RESULT_FIRMWARE    : string := "{{ foxNetwork.resultFirmware.binaryName }}";
    constant RESULT_MEM_SIZE    : integer := {{ foxNetwork.resultFirmware.memSize }};
    {% endif %}

end package firmware_config;

package body firmware_config is

end package body firmware_config;
