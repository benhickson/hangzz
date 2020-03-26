class Meetup < ApplicationRecord

	extend FriendlyId
		friendly_id :slug_candidates, use: :slugged
	
	enum status: { pending: 0, confirmed: 1}
	belongs_to :group
	belongs_to :location



	def slug_candidates
		["#{self.date.strftime("%F")}-#{self.location.name}-#{self.group.name}"]
	end

	def maps_api_call(group_slug)	
		group = Group.friendly.find_by_slug(group_slug)
		locations = Location.all.sample(10)
		
		output_hash = {}

		group_original_commute_times = {}
		group.members.each do |member|
			group_original_commute_times[member] = original_commute_time(member.work_address, member.home_address)
		end

		locations.each do |location|
			commute_difference = 0
			group.members.each do |member|	
				new_commute = new_commute_time(member.work_address, location.address, member.home_address)
				original_commute = group_original_commute_times[member]
				commute_difference += new_commute - original_commute
			end
			output_hash[location] = commute_difference / group.members.count.to_f
		end
		output_hash
  	end

  	def new_commute_time(work_address, meetup_address, home_address)
		response = RestClient.get("https://maps.googleapis.com/maps/api/directions/json?&origin=#{work_address}&waypoints=via:#{meetup_address}&destination=#{home_address}&key=#{gmaps_api_key}")
		parsed = JSON.parse(response.body)
		commute_time = (parsed["routes"][0]["legs"][0]["duration"]["value"].to_f/60)
	end

	def original_commute_time(work_address, home_address)
		request_url = "https://maps.googleapis.com/maps/api/directions/json?&origin=#{work_address}&destination=#{home_address}&key=#{gmaps_api_key}"
		response = RestClient.get(request_url)
		parsed = JSON.parse(response.body)
		commute_time = (parsed["routes"][0]["legs"][0]["duration"]["value"].to_f/60)
	end

	def all
		Meetup.where('status like 1')
	end

	
		

	private

	def gmaps_api_key
		Rails.application.credentials.gmaps[:api_key]
	end

end


# API Call: (GET)
# http://maps.googleapis.com/maps/api/directions/json
# ?key=OUR_AUTH_KEY_JDSKZR98EV
# &origin=work+address
# &waypoints=[bar+or+restaurant+address]
# &destination=home+address
# &mode=transit
# &departure_time=6PM+Wednesday
