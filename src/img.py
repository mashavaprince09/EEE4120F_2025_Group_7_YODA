from matplotlib.image import imread
import matplotlib.pylab as plt
import numpy as np

rgb_image = imread("mage.jpg")
red,green,blue = rgb_image[:,:,0], rgb_image[:,:,1], rgb_image[:,:,2] # Getting the image channels

g = 1.04
r_coeff, g_coeff, b_coeff = 0.2126, 0.7152, 0.0722
grey_image = r_coeff*red**g + g_coeff*green**g + b_coeff*blue**g

fig = plt.figure(1)
img1,img2 = fig.add_subplot(121), fig.add_subplot(122)

img1.imshow(rgb_image)
img2.imshow(grey_image, cmap=plt.cm.get_cmap("gray"))

fig.show()
plt.show()
