package vo

type CategoryID string

const (
	CategoryAnimals     CategoryID = "animals"
	CategoryPlaces      CategoryID = "places"
	CategoryObjects     CategoryID = "objects"
	CategoryFood        CategoryID = "food"
	CategoryCelebrities CategoryID = "celebrities"
	CategoryEras        CategoryID = "eras"
	CategoryMovies      CategoryID = "movies"
	CategorySports      CategoryID = "sports"
	CategoryProfessions CategoryID = "professions"
	CategoryBrands      CategoryID = "brands"
	CategoryBooks       CategoryID = "books"
)

type Category struct {
	ID                CategoryID `json:"id"`
	Name              string     `json:"name"`
	IsJuniorAvailable bool       `json:"is_junior_available"`
}

// GetAvailableCategories returns the MVP category catalog in Spanish.
func GetAvailableCategories() []Category {
	return []Category{
		{ID: CategoryAnimals, Name: "Animales", IsJuniorAvailable: true},
		{ID: CategoryPlaces, Name: "Lugares", IsJuniorAvailable: true},
		{ID: CategoryObjects, Name: "Objetos", IsJuniorAvailable: true},
		{ID: CategoryFood, Name: "Comida", IsJuniorAvailable: true},
		{ID: CategoryCelebrities, Name: "Celebridades", IsJuniorAvailable: false},
		{ID: CategoryEras, Name: "Épocas", IsJuniorAvailable: false},
		{ID: CategoryMovies, Name: "Cine", IsJuniorAvailable: false},
		{ID: CategorySports, Name: "Deportes", IsJuniorAvailable: false},
		{ID: CategoryProfessions, Name: "Profesiones", IsJuniorAvailable: false},
		{ID: CategoryBrands, Name: "Marcas", IsJuniorAvailable: false},
		{ID: CategoryBooks, Name: "Libros", IsJuniorAvailable: false},
	}
}
