package modelhelper

import (
	"koding/db/models"
	"strings"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	CompanyColl = "jCompanies"
)

func CreateCompany(c *models.Company) error {
	if err := c.CheckValues(); err != nil {
		return err
	}

	query := insertQuery(c)
	return Mongo.Run(CompanyColl, query)
}

func UpdateCompany(selector, update bson.M) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, bson.M{"$set": update})
	}

	return Mongo.Run(CompanyColl, query)
}

func GetCompanyById(id string) (*models.Company, error) {
	company := new(models.Company)
	err := Mongo.One(CompanyColl, id, company)
	if err != nil {
		return nil, err
	}

	return company, nil
}

// GetCompanyByName fetches the company with its name,
// company name might be upper or lower case, so we've convert all the names
// to lower case for consistency
func GetCompanyByNameOrSlug(name string) (*models.Company, error) {
	company := new(models.Company)

	cname := strings.ToLower(name)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"slug": cname}).One(&company)
	}

	err := Mongo.Run(CompanyColl, query)
	if err != nil {
		return nil, err
	}

	return company, nil
}

// RemoveCompany removes the company from mongo with company name of company slug
func RemoveCompany(companyName string) error {
	companyName = strings.ToLower(companyName)
	selector := bson.M{"slug": companyName}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(CompanyColl, query)
}
