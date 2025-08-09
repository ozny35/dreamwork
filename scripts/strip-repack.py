import vpk,re,os,sys,shutil,argparse

pathptr = re.compile(r"[\w]:[\\/](.*)")

def check_dir(string):
    if pathptr.match(path):
        return string
    else:
        raise NotADirectoryError(string)

argsparser = argparse.ArgumentParser(
    prog="Garry's mod - Stripdown Repacker",
    description="Creates stripdown (lite) version of game with minimal content",
    epilog="i hate python @ DefaultOS")
argsparser.add_argument("gamepath", nargs='?', type=check_dir)
#argsparser.add_argument("-g", "--gamepath", type=check_dir)
argsparser.add_argument("-o", "--output", type=check_dir)
args = argsparser.parse_args()

SOURCEFOLDER = args.gamepath
if not SOURCEFOLDER:
	print("Input path for game's root...")
	path = input()
	check_dir(path)
	SOURCEFOLDER = path
if not SOURCEFOLDER.endswith(("\\","/")):
	SOURCEFOLDER += os.sep

OUTPUTFOLDER = args.gamepath
if not OUTPUTFOLDER:
	print("Input path for repack output folder...")
	path = input()
	check_dir(path)
	OUTPUTFOLDER = path
if not OUTPUTFOLDER.endswith(("\\","/")):
	OUTPUTFOLDER += os.sep

vpks = [
    "garrysmod/garrysmod_dir.vpk",
    "sourceengine/hl2_misc_dir.vpk",
    "sourceengine/hl2_textures_dir.vpk"
]

def clearline():
	print("\033[K", end="\r")
def progress(str):
	print(str, end="\r")

vpkfilemask = [
    r"scripts/.*",
    r"shaders/.*",

    r"materials/color/.*",
    r"materials/console/.*",
    r"materials/debug/.*",
    r"materials/dev/.*",
    r"materials/cable/.*",
    r"materials/effects/.*",
    r"materials/editor/.*",
    r"materials/engine/.*",
    r"materials/gwenskin/.*",
    r"materials/icon16/.*",
    r"materials/particle/.*",
    r"materials/hlmv/.*",
    r"materials/pp/.*",
    r"materials/tools/.*",
    r"materials/vgui/.*",
    r"materials/gui/.*",
    r"materials/lights/.*",
    r"materials/sprites/.*",
    r"materials/sun/.*",
    r"materials/voice/.*",
    r"materials/models/weapons/.*",

    r"models/error.*",
    r"models/editor/.*",
    r"models/shadertest/.*",
    r"models/vehicles/.*",
    r"models/weapons/.*",

    r"sound/ui/.*",
    r"sound/doors/.*",
    r"sound/buttons/.*",
    r"sound/items/.*",
    r"sound/player/.*",
    r"sound/physics/.*",
]
vpkregex = re.compile('|'.join('(?:{0})'.format(x) for x in vpkfilemask))
vpkoutput = os.path.join(OUTPUTFOLDER, "garrysmod")

print("Repacking game's vpks...")
for vpkpath in vpks:
	vpkfile = vpk.open(SOURCEFOLDER + vpkpath)
	print("	" + vpkpath)
	for filename in vpkfile:
		clearline()
		progress(filename)
		if vpkregex.match(filename):
			syspath = os.path.join(vpkoutput, filename)
			if not os.path.exists(syspath):
				os.makedirs(os.path.dirname(syspath), exist_ok=True)
				vpkfile.get_file(filename).save(syspath)
	clearline()


gamefilemask = [
    r"bin/.*",
    r"platform/.*",

    r"garrysmod/bin/.*",
    r"garrysmod/cfg/.*",
    r"garrysmod/gamemodes/.*",
    r"garrysmod/html/.*",
    r"garrysmod/lua/.*",
    r"garrysmod/particles/.*",
	r"garrysmod/resource/.*",
	r"garrysmod/settings/.*",

    r"garrysmod/(?!.*/).*\.db$",
    r"garrysmod/(?!.*/).*\.vbsp$",
    r"garrysmod/(?!.*/).*\.txt$",
    r"garrysmod/(?!.*/).*\.rad$",
    r"garrysmod/(?!.*/).*\.inf$",

	r"sourceengine/resource/.*",
	r"sourceengine/scripts/.*",

    r"(?!.*/).*\.exe$",
    r"(?!.*/).*\.txt$",
]

gameregex = re.compile('|'.join('(?:{0})'.format(x) for x in gamefilemask))

print("Repacking game files...")
for root, dirs, files in os.walk(SOURCEFOLDER):
	filepath = root[len(SOURCEFOLDER):]
	for file in files:
		filename = os.path.join(filepath, file).replace('\\','/')
		#print(filename)
		clearline()
		progress(filename)
		if gameregex.match(filename):
			syspath = os.path.join(OUTPUTFOLDER, filename)
			if not os.path.exists(syspath):
				os.makedirs(os.path.dirname(syspath), exist_ok=True)
				shutil.copyfile(os.path.join(root, file), syspath)
	clearline()

print("Creating startup bat file.")

with open(os.path.join(OUTPUTFOLDER, "start.bat"), 'w') as file:
	file.write("start gmod.exe -noworkshop -tools -nop4")
