// Code generated by rendertemplates. DO NOT EDIT.

package releases

// List of currently supported releases
var (
	Release118 = mustParse("1.18")
	Release117 = mustParse("1.17")
	Release116 = mustParse("1.16")
	Release115 = mustParse("1.15")
)

// GetAllKymaReleases returns all supported kyma release branches
func GetAllKymaReleases() []*SupportedRelease {
	return []*SupportedRelease{
		Release117,
		Release116,
		Release115,
	}
}

// GetNextKymaRelease returns the version of kyma currently under development
func GetNextKymaRelease() *SupportedRelease {
	return Release118
}
