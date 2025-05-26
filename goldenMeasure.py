from matplotlib.image import imread
import matplotlib.image as mpimg
import matplotlib.pylab as plt
import numpy as np
import sys
import time

def load_from_image(path):
    """Load an image, converts it to grey_scale and returns it as a numpy array."""
    rgb_image = imread(path) # Read in the image
    red,green,blue = rgb_image[:,:,0], rgb_image[:,:,1], rgb_image[:,:,2] # Getting the image channels

    # Human-eye friendly grayscale conversion
    g = 1.04
    r_coeff, g_coeff, b_coeff = 0.2126, 0.7152, 0.0722
    return r_coeff*red**g + g_coeff*green**g + b_coeff*blue**g


def print_image(gray_image):
    """ Plot the image using Matplotlib.pyplot """
    fig = plt.figure(1)

    fig.imshow(gray_image, cmap=plt.cm.get_cmap("gray"))

    fig.show()
    plt.show()


def save_hex(image_array, fileName):
    """Save an image array as a .hex file"""
    r,c = image_array.shape[0],image_array.shape[1]
    with open(f'{fileName}', 'w') as f:
        for i in range(r):
            for j in range(c):
                if i==r-1 and j==c-1:
                    f.write(f"{image_array[i,j]:x}")
                else:
                    f.write(f"{image_array[i,j]:x}\n")
        f.write("\n")


def getHex(hexFilename):
    """ Load in a hex file and store it in a numpy array"""
    with open(hexFilename, 'r') as f:
        hex_data = f.read().split()

    # Convert hex strings to integers
    int_data = [int(byte, 16) for byte in hex_data]

    # Convert to NumPy array
    arr = np.array(int_data, dtype=np.uint8)
    #print(arr)

    return arr.reshape((512, 512))

def save_as_image(output_fileName, image_array):
    """ Save a numpy image as a .png file """
    mpimg.imsave(output_fileName, image_array, cmap='gray') # Save as png

def medianFilter(arr):
    """ Median Filter implementation """

    a,b = np.shape(arr) # a=num_of_rows, b=num_of_columns

    result = np.zeros((a,b), dtype=np.uint8) # to store the median filtered Result

    for i in range(a):
        for j in range(b):

            if(i==0 or i==a-1 or j==0 or j==b-1): # Egdge pixels
                result[i][j] = arr[i][j] # Echo edge pixels
            else:
                result[i][j] = (np.median(arr[i-1:i+2, j-1:j+2])) # Store the 3x3 Median value
            result

    return result


def sobel_filter(image):
    # Define Sobel kernels
    Kx = np.array([[ -1,  0,  1],
                   [ -2,  0,  2],
                   [ -1,  0,  1]]) # dz/dx

    Ky = np.array([[ -1, -2, -1],
                   [  0,  0,  0],
                   [  1,  2,  1]]) #dx/dy

    # Image dimensions
    h, w = image.shape

    # Output gradient magnitude image
    output = np.zeros((h, w), dtype=np.uint8)
    
    thresh = 150 # Endge threshold
    
    # Apply convolution
    for i in range(1, h-1):
        for j in range(1, w-1):

            region = image[i-1:i+2, j-1:j+2] # get subset to be filtered
            gx = np.sum(Kx * region)         # x-axis derivative
            gy = np.sum(Ky * region)         # y-axis derivative

            temp = (abs(gx) + abs(gy))       # approximate magnitude using manhatton distance
            
            # Thresholding
            if(temp > thresh):
                output[i,j] = 255
            else:
                output[i,j] = 0

    return output # Return the result

def main():

    # Menu
    print("choose mode:")
    print("Unfiltered: [0]")
    print("Filetered: [1]")

    mode = int(input())         # Get user input
    

    start = time.time()         # Simulation starting point
    img = getHex(sys.argv[1])   # Load the .hex file  (communication overhead)

    start2 = time.time()        # Strart of critical part (Part to be parallelized)

    if mode == 0:
        img2 = sobel_filter(img) # No median filter -> just edge detection
    else:
        img3 = medianFilter(img)  # Median filtering + edge detection
        img2 = sobel_filter(img3)

    critical_time = (time.time()-start2) * 1e9 # critcal section end (Parallelized part)

    save_hex(img2, 'out/golden_sobel.hex')     # Upload file (communication overhead)
    full_time = (time.time()-start) * 1e9     # Total execution time (Get total execution time)

    save_as_image('out/goldenOutput.png', img2)     # Produce png image (For Viewing)

    #Print outputs
    print("Critical Section Time:", critical_time)
    print("Total Time:", full_time)
    

if __name__ == "__main__":
    main()




