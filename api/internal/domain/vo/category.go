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

func categoryName(id CategoryID, language Language) string {
	switch NormalizeLanguage(string(language)) {
	case LanguageEnglish:
		switch id {
		case CategoryAnimals:
			return "Animals"
		case CategoryPlaces:
			return "Places"
		case CategoryObjects:
			return "Objects"
		case CategoryFood:
			return "Food"
		case CategoryCelebrities:
			return "Celebrities"
		case CategoryEras:
			return "Eras"
		case CategoryMovies:
			return "Movies"
		case CategorySports:
			return "Sports"
		case CategoryProfessions:
			return "Professions"
		case CategoryBrands:
			return "Brands"
		case CategoryBooks:
			return "Books"
		}
	default:
		switch id {
		case CategoryAnimals:
			return "Animales"
		case CategoryPlaces:
			return "Lugares"
		case CategoryObjects:
			return "Objetos"
		case CategoryFood:
			return "Comida"
		case CategoryCelebrities:
			return "Celebridades"
		case CategoryEras:
			return "Épocas"
		case CategoryMovies:
			return "Cine"
		case CategorySports:
			return "Deportes"
		case CategoryProfessions:
			return "Profesiones"
		case CategoryBrands:
			return "Marcas"
		case CategoryBooks:
			return "Libros"
		}
	}

	return string(id)
}

// GetAvailableCategories returns the MVP category catalog in the requested language.
func GetAvailableCategories(language Language) []Category {
	ids := []CategoryID{
		CategoryAnimals,
		CategoryPlaces,
		CategoryObjects,
		CategoryFood,
		CategoryCelebrities,
		CategoryEras,
		CategoryMovies,
		CategorySports,
		CategoryProfessions,
		CategoryBrands,
		CategoryBooks,
	}

	juniorAvailable := map[CategoryID]bool{
		CategoryAnimals: true,
		CategoryPlaces:  true,
		CategoryObjects: true,
		CategoryFood:    true,
	}

	categories := make([]Category, 0, len(ids))
	for _, id := range ids {
		categories = append(categories, Category{
			ID:                id,
			Name:              categoryName(id, language),
			IsJuniorAvailable: juniorAvailable[id],
		})
	}

	return categories
}
