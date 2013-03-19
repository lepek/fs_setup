fs_path = '/usr/local/freeswitch'
ip = '192.168.1.202'
re_ip = '192.168.1.201'

files = [
	{
		:filename => '00_adhearsion.xml',
		:path => "#{fs_path}/conf/dialplan/default/"
	},
	{
		:filename => 'sansay_out.xml',
		:path => "#{fs_path}/conf/sip_profiles/external/"
	}
]

data = [
	{
		:filename => "#{fs_path}/conf/sip_profiles/external.xml",
		:replace => [
			{
				:original => '<param name="ext-rtp-ip" value="auto-nat"/>',
				:new => '<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>'
			},
			{
				:original => '<param name="ext-sip-ip" value="auto-nat"/>',
				:new => ' <param name="ext-sip-ip" value="$${external_sip_ip}"/>'
			},
			{
                :original => '<param name="context" value="public"/>',
                :new => '<param name="context" value="default"/>'
            }
		]
	},
	{
		:filename => "#{fs_path}/conf/sip_profiles/internal.xml",
		:replace => [
			{
				:original => '<param name="ext-rtp-ip" value="auto-nat"/>',
				:new => '<param name="ext-rtp-ip" value="$${external_rtp_ip}"/>'
			},
			{
				:original => '<param name="ext-sip-ip" value="auto-nat"/>',
				:new => '<param name="ext-sip-ip" value="$${external_sip_ip}"/>'
			}
		]
	},
	{
		:filename => "#{fs_path}/conf/vars.xml",
		:replace => [
			{
				:original => '<X-PRE-PROCESS cmd="set" data="bind_server_ip=auto"/>',
				:new => '<X-PRE-PROCESS cmd="set" data="bind_server_ip=$${local_ip_v4}"/>'
			},
			{
				:original => '<X-PRE-PROCESS cmd="set" data="external_rtp_ip=stun:stun.freeswitch.org"/>',
				:new => '<X-PRE-PROCESS cmd="set" data="external_rtp_ip=$${local_ip_v4}"/>'
			},
			{
				:original => '<X-PRE-PROCESS cmd="set" data="external_sip_ip=stun:stun.freeswitch.org"/>',
				:new => '<X-PRE-PROCESS cmd="set" data="external_sip_ip=$${local_ip_v4}"/>'
			},
			{
				:original => '<X-PRE-PROCESS cmd="set" data="domain=\$\$\{local_ip_v4\}"/>',
				:new => '<X-PRE-PROCESS cmd="set" data="local_ip_v4=' + ip + '"/>' + "\n" + 
					'<X-PRE-PROCESS cmd="set" data="domain=$${local_ip_v4}"/>' + "\n" +
					'<X-PRE-PROCESS cmd="set" data="re_engine_ip=' + re_ip + '"/>'
			}
		]
	},
	{
		:filename => "#{fs_path}/conf/autoload_configs/acl.conf.xml",
		:replace => [
			{
				:original => '<list name="domains" default="deny">',
				:new => '<list name="domains" default="deny">' + "\n" +
							'<node type="allow" cidr="$${re_engine_ip}/24"/>' + "\n"
			}
		]
	}	
]

def replace(susts, string)
	susts.each do |sust|
		new_string = string.gsub(/#{sust[:original]}/, sust[:new])
		string = new_string
	end
	string
end

data.each do |file|
	if File.exist?(file[:filename])
		text = File.read(file[:filename])
		new_text = replace(file[:replace], text)
		
		## Make a backup
		File.open("#{file[:filename]}.bak", "w") { |backup| backup << text }

		File.open(file[:filename], "w") { |existing| existing << new_text }
		puts "#{file[:filename]} processed \n"
	else
		puts "#{file[:filename]} does not exist \n"
	end
end

files.each do |file|
	filename = file[:path] + file[:filename]
	if File.exist?(file[:filename])
		string = File.read(file[:filename])
		File.open(filename, "w") { |new_file| new_file << string }
		puts "#{file[:filename]} created \n"
	else
		puts "#{filename} does not exist \n"
	end
end
