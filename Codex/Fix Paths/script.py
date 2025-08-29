#!/usr/bin/env python3
"""
Image resizer script for Dungeondraft textures.
Resizes PNG images to multiples of 128 (width) and 64 (height).
- Scales width to nearest multiple of 128
- Adds transparency padding to top/bottom to reach nearest multiple of 64 for height
- Outputs with _codex.png suffix
"""

import os
import math
from PIL import Image, ImageOps

def get_nearest_multiple(value, multiple):
    """Get the nearest multiple of a given number."""
    return math.ceil(value / multiple) * multiple

def resize_image_to_codex_format(input_path, output_path):
    """
    Resize an image according to codex specifications:
    - Width: nearest multiple of 128
    - Height: nearest multiple of 64 (with transparency padding)
    """
    try:
        # Open the image
        with Image.open(input_path) as img:
            # Convert to RGBA if not already (to handle transparency)
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            original_width, original_height = img.size
            print(f"Processing {os.path.basename(input_path)}: {original_width}x{original_height}")
            
            # Calculate target width (nearest multiple of 128)
            target_width = get_nearest_multiple(original_width, 128)
            
            # Scale the image to the target width, maintaining aspect ratio
            scale_factor = target_width / original_width
            scaled_height = int(original_height * scale_factor)
            
            # Resize the image
            scaled_img = img.resize((target_width, scaled_height), Image.Resampling.LANCZOS)
            
            # Calculate target height (nearest multiple of 64)
            target_height = get_nearest_multiple(scaled_height, 64)
            
            # Create a new image with the target dimensions and transparent background
            final_img = Image.new('RGBA', (target_width, target_height), (0, 0, 0, 0))
            
            # Calculate padding for centering vertically
            padding_top = (target_height - scaled_height) // 2
            
            # Paste the scaled image onto the final image
            final_img.paste(scaled_img, (0, padding_top), scaled_img)
            
            # Save the result
            final_img.save(output_path, 'PNG')
            print(f"  -> Saved as {os.path.basename(output_path)}: {target_width}x{target_height}")
            
    except Exception as e:
        print(f"Error processing {input_path}: {str(e)}")

def main():
    """Main function to process all PNG files in the current directory."""
    current_dir = os.getcwd()
    
    # Find all PNG files in the current directory
    png_files = [f for f in os.listdir(current_dir) 
                 if f.lower().endswith('.png') and not f.endswith('_codex.png')]
    
    if not png_files:
        print("No PNG files found in the current directory.")
        return
    
    print(f"Found {len(png_files)} PNG files to process...")
    print()
    
    # Process each PNG file
    for png_file in png_files:
        input_path = os.path.join(current_dir, png_file)
        
        # Create output filename with _codex suffix
        name, ext = os.path.splitext(png_file)
        output_filename = f"{name}_codex{ext}"
        output_path = os.path.join(current_dir, output_filename)
        
        resize_image_to_codex_format(input_path, output_path)
    
    print()
    print(f"Processing complete! {len(png_files)} files processed.")

if __name__ == "__main__":
    main()
