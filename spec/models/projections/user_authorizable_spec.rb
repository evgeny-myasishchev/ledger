require 'rails_helper'

RSpec.describe Projections::UserAuthorizable do
  subject {
    Class.new do
      include Projections::UserAuthorizable
      attr_accessor :authorized_user_ids
      attr_reader :authorized_user_ids_will_change_called
      def authorized_user_ids_will_change!
        @authorized_user_ids_will_change_called = true
      end
    end.new
  }

  describe "set_authorized_users" do
    it "should initialize the authorized_user_ids with provided users" do
      subject.set_authorized_users([22, 23, 25, 31])
      expect(subject.authorized_user_ids).to eql '{22},{23},{25},{31}'
    end
  end

  describe "authorize_user" do
    it "should insert the user into authorized_user_ids" do
      subject.authorized_user_ids = '';
      subject.authorize_user 10
      expect(subject.authorized_user_ids).to eql('{10}')
      expect(subject.authorized_user_ids_will_change_called).to be_truthy

      subject.authorized_user_ids = '{22},{23}';
      subject.authorize_user 25
      subject.authorize_user 31
      expect(subject.authorized_user_ids).to eql '{22},{23},{25},{31}'
    end
  end
end