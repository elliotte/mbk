require 'spec_helper'
require 'user'

describe User do

let(:user) { User.new }

	context "User attribtues" do

		it { is_expected.to respond_to(:transactions) }
		#it { is_expected.to respond_to(:bookings) }

		it { is_expected.to respond_to(:id) }
		it { is_expected.to respond_to(:email) }
		it { is_expected.to respond_to(:uid) }
		it { is_expected.to respond_to(:provider) }
		
	end


 end
