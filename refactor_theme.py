import os
import re

lib_dir = '/Users/zul/Documents/final year project/finalyearproject/lib'
colors_path = os.path.join(lib_dir, 'core/constants/app_colors.dart')
text_styles_path = os.path.join(lib_dir, 'core/constants/app_text_styles.dart')
extensions_path = os.path.join(lib_dir, 'core/styles/app_theme_extensions.dart')

with open(colors_path, 'r') as f:
    colors_code = f.read()

app_colors_props = []
app_dark_colors_props = []

# Parse AppColors
app_colors_match = re.search(r'class AppColors \{(.*?)\}', colors_code, re.DOTALL)
if app_colors_match:
    props = re.findall(r'static const (Color|LinearGradient) (\w+) =', app_colors_match.group(1))
    for p in props:
        app_colors_props.append(p[1])

# Parse AppDarkColors
app_dark_colors_match = re.search(r'class AppDarkColors \{(.*?)\}', colors_code, re.DOTALL)
if app_dark_colors_match:
    props = re.findall(r'static const Color (\w+) =', app_dark_colors_match.group(1))
    for p in props:
        app_dark_colors_props.append(p)

with open(text_styles_path, 'r') as f:
    text_styles_code = f.read()

app_text_styles_props = []
app_text_styles_match = re.search(r'class AppTextStyles \{(.*?)\}', text_styles_code, re.DOTALL)
if app_text_styles_match:
    props = re.findall(r'static TextStyle get (\w+) =>', app_text_styles_match.group(1))
    for p in props:
        app_text_styles_props.append(p)

# Generate extension file
ext_code = """import 'package:flutter/material.dart';
import 'package:finalyearproject/core/constants/app_colors.dart';
import 'package:finalyearproject/core/constants/app_text_styles.dart';

class ThemeColors {
  final BuildContext context;
  ThemeColors(this.context);
  
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

"""
for prop in app_colors_props:
    if prop == 'primaryGradient':
        ext_code += f"  LinearGradient get {prop} => AppColors.{prop};\n"
        continue
        
    if prop in app_dark_colors_props:
        ext_code += f"  Color get {prop} => _isDark ? AppDarkColors.{prop} : AppColors.{prop};\n"
    else:
        ext_code += f"  Color get {prop} => AppColors.{prop};\n"

ext_code += """}

class ThemeTextStyles {
  final BuildContext context;
  ThemeTextStyles(this.context);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

"""

for prop in app_text_styles_props:
    # Use context.appColors.textPrimary/Secondary instead of AppColors if possible, but actually it's easier to just use AppDarkColors.
    # We will just copyWith(color: context.appColors.textPrimary) if it's a generic text style.
    # Let's inspect what color it uses by default. But a safer approach is to just map it:
    ext_code += f"  TextStyle get {prop} => _isDark ? AppTextStyles.{prop}.copyWith(color: AppDarkColors.textPrimary) : AppTextStyles.{prop};\n"

ext_code += """}

extension AppThemeExtension on BuildContext {
  ThemeColors get appColors => ThemeColors(this);
  ThemeTextStyles get appTextStyles => ThemeTextStyles(this);
}
"""

with open(extensions_path, 'w') as f:
    f.write(ext_code)
print("Created app_theme_extensions.dart")

# Now refactor lib/modules and lib/shared
directories = [os.path.join(lib_dir, 'modules'), os.path.join(lib_dir, 'shared')]
files_changed = 0

import_statement = "import 'package:finalyearproject/core/styles/app_theme_extensions.dart';"

for d in directories:
    for root, dirs, files in os.walk(d):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                new_content = content
                new_content = re.sub(r'\bAppColors\.', 'context.appColors.', new_content)
                new_content = re.sub(r'\bAppTextStyles\.', 'context.appTextStyles.', new_content)
                
                if new_content != content:
                    # check if we need to add the import
                    if 'app_theme_extensions.dart' not in new_content:
                        # find last import
                        imports = list(re.finditer(r"^import\s+['\"].*?['\"];", new_content, re.MULTILINE))
                        if imports:
                            last_import = imports[-1]
                            pos = last_import.end()
                            new_content = new_content[:pos] + "\n" + import_statement + new_content[pos:]
                        else:
                            new_content = import_statement + "\n\n" + new_content
                    
                    with open(filepath, 'w') as f:
                        f.write(new_content)
                    files_changed += 1

print(f"Refactored {files_changed} files.")
