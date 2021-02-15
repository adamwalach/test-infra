// Code generated by rendertemplates. DO NOT EDIT.

package releases

// List of currently supported releases
var (
	Release121 = mustParse("1.21")
	Release120 = mustParse("1.20")
	Release119 = mustParse("1.19")
	Release118 = mustParse("1.18")
)

// GetAllKymaReleases returns all supported kyma release branches
func GetAllKymaReleases() []*SupportedRelease {
	return []*SupportedRelease{
		Release120,
		Release119,
		Release118,
	}
}

// GetNextKymaRelease returns the version of kyma currently under development
func GetNextKymaRelease() *SupportedRelease {
	return Release121
}
