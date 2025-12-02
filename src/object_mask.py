from dataclasses import dataclass
import numpy as np
import scipy.ndimage


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

	def is_overlapping(self, other: 'ObjectMask', padding: int = 2) -> bool:
		# Create padded masks
		padded_self = scipy.ndimage.binary_dilation(self.mask, iterations=padding)
		padded_other = scipy.ndimage.binary_dilation(other.mask, iterations=padding)
		
		# Calculate overlap
		overlap = np.logical_and(padded_self, padded_other)
		return np.any(overlap)
