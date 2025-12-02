from dataclasses import dataclass
import numpy as np
import scipy.ndimage
import matplotlib.pyplot as plt

@dataclass
class ObjectMask:
	label: str
	mask: np.ndarray

	def __post_init__(self):
		if not isinstance(self.mask, np.ndarray):
			raise TypeError("mask must be a numpy ndarray")
		unique_vals = np.unique(self.mask)
		if sorted(unique_vals) != [0, 1]:
			raise ValueError("mask must be a binary array containing both 0s and 1s only")
		if self.mask.ndim != 2:
			raise ValueError("mask must be a 2D array")


	def area(self) -> int:
		return np.sum(self.mask)

	def is_overlapping(self, other: 'ObjectMask', padding: int = 10) -> bool:
		padded_self = self.mask
		padded_other = other.mask

		if padding > 0:
			padded_self = scipy.ndimage.binary_dilation(self.mask, iterations=padding)
			padded_other = scipy.ndimage.binary_dilation(other.mask, iterations=padding)
		
		# Calculate overlap
		overlap = np.logical_and(padded_self, padded_other)
		return np.any(overlap)

@dataclass
class ObjectMaskWithDepth(ObjectMask):
	full_depth_map: np.ndarray

	def __post_init__(self):
		super().__post_init__()
		if not isinstance(self.full_depth_map, np.ndarray):
			raise TypeError("depth must be a numpy ndarray")
		if self.full_depth_map.shape != self.mask.shape:
			raise ValueError("depth must have the same shape as mask")
	
	@property
	def masked_depth_map(self) -> np.ndarray:
		return self.full_depth_map * self.mask
	
	def is_deeper(self, other: 'ObjectMaskWithDepth', padding: int = 10) -> bool:
		padded_self = self.mask
		padded_other = other.mask

		if padding > 0:
			padded_self = scipy.ndimage.maximum_filter(padded_self, padding)
			padded_other = scipy.ndimage.maximum_filter(padded_other, padding)
		
		overlap = np.logical_and(padded_self, padded_other)
		if np.any(overlap):
			filtered_self = overlap * padded_self
			filtered_other = overlap * padded_other
			
			self_overlap_depth = np.nonzero(filtered_self).mean()
			other_overlap_depth = np.nonzero(filtered_other).mean()
			return self_overlap_depth < other_overlap_depth
		else:
			self_depth = padded_self.mean()
			other_depth = padded_other.mean()
			return self_depth < other_depth

	def render_depth_image(self) -> np.ndarray:
		"""Apply segmentation mask to depth map with original image as background"""
		min_depth = self.full_depth_map.min()
		max_depth = self.full_depth_map.max()

		depth_normalized = ((self.masked_depth_map - min_depth) / (max_depth - min_depth) * 255).astype(np.uint8)
    
		# Apply colormap to depth (inferno)
		cmap = plt.get_cmap('inferno')
		depth_colored = (cmap(depth_normalized / 255.0)[:, :, :3] * 255).astype(np.uint8)
		
		# Create composite: depth where mask is True, black where mask is False
		mask_3d = np.stack([self.masked_depth_map, self.masked_depth_map, self.masked_depth_map], axis=-1)  # Make mask 3D for RGB
		depth_image = np.where(mask_3d, depth_colored, 0)  # Black background where mask is False
		
		return depth_image
