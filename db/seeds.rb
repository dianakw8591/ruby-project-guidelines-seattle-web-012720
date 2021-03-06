require 'net/http'
require 'open-uri'
require 'json'
require 'date'

RecArea.delete_all
RecArea.reset_pk_sequence

Campground.delete_all
Campground.reset_pk_sequence

Availability.delete_all
Availability.reset_pk_sequence

User.delete_all
User.reset_pk_sequence

Alert.delete_all
Alert.reset_pk_sequence
 

rec_codes = ["2991", "2782", "2931", "2662", "2558", "2631", "2803", "2893", "2901"]

# API request and parsing
def get_request_for_rec_data(url)
    RestClient::Request.execute(method: :get, 
    url: url,
    headers: {
        apiKey: ENV['API_KEY']
        }
    )
end

def parse_json(url)
    JSON.parse(get_request_for_rec_data(url))
end

# RecArea seeding

def seed_rec_area_row(rec_hash)
    name = rec_hash["RecAreaName"]
    id = rec_hash["RecAreaID"]
    description = rec_hash["RecAreaDescription"]
    RecArea.create(name: name, official_rec_area_id: id, description: description)
end

def populate_rec_table(id_array)
    base_url = "https://ridb.recreation.gov/api/v1/recareas/"
    id_array.each do |id|
        url = base_url + id
        rec_hash = parse_json(url)
        seed_rec_area_row(rec_hash)
    end
end

# Campground seeding

def seed_campground_row(campground_hash, i)
    name = campground_hash["FacilityName"]
    id = campground_hash["FacilityID"]
    description = campground_hash["FacilityDescription"]
    camp = Campground.create(name: name, official_facility_id: id, description: description)
    RecArea.find_by(official_rec_area_id: i).campgrounds << camp
end

def populate_campground_table(rec_id_array)
    base_url = "https://ridb.recreation.gov/api/v1/recareas/"
    rec_id_array.each do |id|
        url = base_url + id + "/facilities"
        campground_hash = parse_json(url)
        campground_hash["RECDATA"].each do |campground|
            if campground["FacilityTypeDescription"] == "Campground"
                seed_campground_row(campground, id)
            end
        end
    end
end

# availability table - fake availability for now

def populate_availability_table
    Campground.all.each do |camp|
        date = Date.today
        while date < Date.today.next_month do
            sites = Random.rand(10)
            avail = Availability.create(date: date, open?: true, sites_available: sites)
            camp.availabilities << avail
            date = date.next
        end
    end
end



populate_rec_table(rec_codes)
populate_campground_table(rec_codes)
populate_availability_table
