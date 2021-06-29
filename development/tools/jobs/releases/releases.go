// Code generated by rendertemplates. DO NOT EDIT.

package releases

// List of currently supported releases
var (
	Release20  = mustParse("2.0")
	Release20 = mustParse("2.0")
	Release124 = mustParse("1.24")
	Release123 = mustParse("1.23")
	Release122 = mustParse("1.22")
)

// GetAllKymaReleases returns all supported kyma release branches
func GetAllKymaReleases() []*SupportedRelease {
	return []*SupportedRelease{
		Release20,
		Release124,
		Release123,
		Release122,
	}
}

// GetNextKymaRelease returns the version of kyma currently under development
func GetNextKymaRelease() *SupportedRelease {
	return Release20
}
