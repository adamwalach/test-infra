// Code generated by rendertemplates. DO NOT EDIT.

package releases

// List of currently supported releases
var (
	Release119 = mustParse("1.19")
	Release118 = mustParse("1.18")
	Release117 = mustParse("1.17")
	Release116 = mustParse("1.16")
)

// GetAllKymaReleases returns all supported kyma release branches
func GetAllKymaReleases() []*SupportedRelease {
	return []*SupportedRelease{
		Release118,
		Release117,
		Release116,
	}
}

// GetNextKymaRelease returns the version of kyma currently under development
func GetNextKymaRelease() *SupportedRelease {
	return Release119
}
