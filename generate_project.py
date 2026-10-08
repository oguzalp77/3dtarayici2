import os
import hashlib

def make_id(name):
    # Generates a reproducible 24-character hex ID for PBX
    h = hashlib.md5(name.encode('utf-8')).hexdigest()[:24].upper()
    return h

project_name = "BambuScan3D"
source_dir = "BambuScan3D"

swift_files = []
for root, dirs, files in os.walk(source_dir):
    for f in files:
        if f.endswith(".swift"):
            rel_path = os.path.relpath(os.path.join(root, f), source_dir).replace("\\", "/")
            swift_files.append((f, rel_path))

print(f"Found {len(swift_files)} Swift files.")

pbx_objects = []

# File references & Build files
build_file_ids = []
fileref_entries = []
buildfile_entries = []

for fname, rel in swift_files:
    f_id = make_id("FILE_" + rel)
    b_id = make_id("BUILD_" + rel)
    build_file_ids.append(b_id)
    fileref_entries.append(f'\t\t{f_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{fname}"; sourceTree = "<group>"; }};')
    buildfile_entries.append(f'\t\t{b_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {fname} */; }};')

# Info.plist
plist_fid = make_id("FILE_Info.plist")
fileref_entries.append(f'\t\t{plist_fid} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};')

# App product
app_fid = make_id("PROD_BambuScan3D.app")
fileref_entries.append(f'\t\t{app_fid} /* {project_name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "{project_name}.app"; sourceTree = BUILT_PRODUCTS_DIR; }};')

# Groups
# Subgroups for App, Models, Scanning, Processing, Exporters, BambuIntegration, Views, Components
groups_dict = {}
for fname, rel in swift_files:
    parts = rel.split('/')
    if len(parts) == 1:
        group_path = ""
    elif len(parts) == 2:
        group_path = parts[0]
    else:
        group_path = "/".join(parts[:-1])
    
    if group_path not in groups_dict:
        groups_dict[group_path] = []
    groups_dict[group_path].append((fname, rel))

group_entries = []

# We'll create groups
components_gid = make_id("GRP_Views_Components")
views_gid = make_id("GRP_Views")
app_gid = make_id("GRP_App")
models_gid = make_id("GRP_Models")
scanning_gid = make_id("GRP_Scanning")
processing_gid = make_id("GRP_Processing")
exporters_gid = make_id("GRP_Exporters")
bambu_gid = make_id("GRP_BambuIntegration")
products_gid = make_id("GRP_Products")
main_src_gid = make_id("GRP_BambuScan3D_Source")
root_gid = make_id("GRP_Root")

def format_children(items):
    return "\n".join([f'\t\t\t\t{make_id("FILE_" + rel)} /* {fname} */,' for fname, rel in items])

# Components group
comp_children = format_children(groups_dict.get("Views/Components", []))
group_entries.append(f'''\t\t{components_gid} /* Components */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{comp_children}
\t\t\t);
\t\t\tpath = Components;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Views group
views_items = [f'\t\t\t\t{components_gid} /* Components */,']
for fname, rel in groups_dict.get("Views", []):
    views_items.append(f'\t\t\t\t{make_id("FILE_" + rel)} /* {fname} */,')
views_children = "\n".join(views_items)
group_entries.append(f'''\t\t{views_gid} /* Views */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{views_children}
\t\t\t);
\t\t\tpath = Views;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# App
app_children = format_children(groups_dict.get("App", []))
group_entries.append(f'''\t\t{app_gid} /* App */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{app_children}
\t\t\t);
\t\t\tpath = App;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Models
models_children = format_children(groups_dict.get("Models", []))
group_entries.append(f'''\t\t{models_gid} /* Models */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{models_children}
\t\t\t);
\t\t\tpath = Models;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Scanning
scanning_children = format_children(groups_dict.get("Scanning", []))
group_entries.append(f'''\t\t{scanning_gid} /* Scanning */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{scanning_children}
\t\t\t);
\t\t\tpath = Scanning;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Processing
processing_children = format_children(groups_dict.get("Processing", []))
group_entries.append(f'''\t\t{processing_gid} /* Processing */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{processing_children}
\t\t\t);
\t\t\tpath = Processing;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Exporters
exporters_children = format_children(groups_dict.get("Exporters", []))
group_entries.append(f'''\t\t{exporters_gid} /* Exporters */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{exporters_children}
\t\t\t);
\t\t\tpath = Exporters;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# BambuIntegration
bambu_children = format_children(groups_dict.get("BambuIntegration", []))
group_entries.append(f'''\t\t{bambu_gid} /* BambuIntegration */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{bambu_children}
\t\t\t);
\t\t\tpath = BambuIntegration;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Main source group
group_entries.append(f'''\t\t{main_src_gid} /* BambuScan3D */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_gid} /* App */,
\t\t\t\t{models_gid} /* Models */,
\t\t\t\t{scanning_gid} /* Scanning */,
\t\t\t\t{processing_gid} /* Processing */,
\t\t\t\t{exporters_gid} /* Exporters */,
\t\t\t\t{bambu_gid} /* BambuIntegration */,
\t\t\t\t{views_gid} /* Views */,
\t\t\t\t{plist_fid} /* Info.plist */,
\t\t\t);
\t\t\tpath = BambuScan3D;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Products group
group_entries.append(f'''\t\t{products_gid} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_fid} /* {project_name}.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Root group
group_entries.append(f'''\t\t{root_gid} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{main_src_gid} /* BambuScan3D */,
\t\t\t\t{products_gid} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};''')

# Target and Build Phases
target_id = make_id("TARGET_BambuScan3D")
sources_phase_id = make_id("PHASE_Sources")
frameworks_phase_id = make_id("PHASE_Frameworks")
resources_phase_id = make_id("PHASE_Resources")

sources_list = "\n".join([f'\t\t\t\t{b_id} /* in Sources */,' for b_id in build_file_ids])

phases_entries = f'''\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_list}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};'''

# Native Target
target_entry = f'''\t\t{target_id} /* {project_name} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {make_id("CFG_LIST_Target")} /* Build configuration list for PBXNativeTarget "{project_name}" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {project_name};
\t\t\tproductName = {project_name};
\t\t\tproductReference = {app_fid} /* {project_name}.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};'''

# Project Object
project_obj_id = make_id("PROJECT_Root")
project_entry = f'''\t\t{project_obj_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {make_id("CFG_LIST_Project")} /* Build configuration list for PBXProject "{project_name}" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {root_gid};
\t\t\tproductRefGroup = {products_gid} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id} /* {project_name} */,
\t\t\t);
\t\t}};'''

# Build Configurations
cfg_debug_target = make_id("CFG_Debug_Target")
cfg_release_target = make_id("CFG_Release_Target")
cfg_debug_proj = make_id("CFG_Debug_Proj")
cfg_release_proj = make_id("CFG_Release_Proj")

config_entries = f'''\t\t{cfg_debug_target} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = BambuScan3D/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.bambuscan.BambuScan3D;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{cfg_release_target} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = BambuScan3D/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.bambuscan.BambuScan3D;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{cfg_debug_proj} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{cfg_release_proj} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};'''

cfg_lists = f'''\t\t{make_id("CFG_LIST_Target")} /* Build configuration list for PBXNativeTarget "{project_name}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{cfg_debug_target} /* Debug */,
\t\t\t\t{cfg_release_target} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{make_id("CFG_LIST_Project")} /* Build configuration list for PBXProject "{project_name}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{cfg_debug_proj} /* Debug */,
\t\t\t\t{cfg_release_proj} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};'''

pbx_content = f'''// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(buildfile_entries)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(fileref_entries)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{chr(10).join(group_entries)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
{target_entry}
/* End PBXNativeTarget section */

/* Begin PBXProject section */
{project_entry}
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_list}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
{config_entries}
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
{cfg_lists}
/* End XCConfigurationList section */

\t}};
\trootObject = {project_obj_id} /* Project object */;
}}
'''

os.makedirs("BambuScan3D.xcodeproj", exist_ok=True)
with open("BambuScan3D.xcodeproj/project.pbxproj", "w", encoding="utf-8") as f:
    f.write(pbx_content)

print("Successfully generated BambuScan3D.xcodeproj/project.pbxproj!")
