require 'rails_helper'

module PendingTransactionsControllerSpec
  include Application::Commands::PendingTransactionCommands

  RSpec.describe PendingTransactionsController, :type => :controller do
    include AuthenticationHelper
    authenticate_user
    
    describe "routes", :type => :routing do
      it "routes GET 'index'" do
        expect({get: 'pending-transactions'}).to route_to controller: 'pending_transactions', action: 'index'
      end
      
      it "routes POST 'report'" do
        expect({post: 'pending-transactions'}).to route_to controller: 'pending_transactions', action: 'report'
      end
    
      it "routes PUT 'adjust'" do
        expect({put: 'pending-transactions/t-110'}).to route_to controller: 'pending_transactions', action: 'adjust', id: 't-110'
      end
    
      it "routes POST 'approve'" do
        expect({post: 'pending-transactions/t-110/approve'}).to route_to controller: 'pending_transactions', action: 'approve', id: 't-110'
      end
      
      it "routes POST 'adjust-and-approve'" do
        expect({post: 'pending-transactions/t-110/adjust-and-approve'}).to route_to controller: 'pending_transactions', action: 'adjust_and_approve', id: 't-110'
      end
      
      it "routes DELETE to destroy" do
        expect({delete: 'pending-transactions/t-110'}).to route_to controller: 'pending_transactions', action: 'destroy', id: 't-110'
      end
    end
    
    describe 'GET index' do
      it 'should query user pending transactions and return them' do
        transactions = double(:transactions)
        expect(Projections::PendingTransaction).to receive(:get_pending_transactions).with(controller.current_user).and_return(transactions)
        get 'index', format: :json
        expect(assigns(:transactions)).to be transactions
        expect(response.status).to eql 200
      end
    end
  
    describe 'POST report' do
      it 'should dispatch report command' do
        date = DateTime.new
        expect(controller).to receive(:dispatch_command) do |command|
          expect(command).to be_an_instance_of ReportPendingTransaction
          expect(command.id).to eql 't-100'
          expect(command.user).to be controller.current_user
          expect(command.amount).to eql '222.32'
          expect(command.date).to eql date
          expect(command.tag_ids).to eql ['t-1', 't-2']
          expect(command.comment).to eql 'Comment 100'
          expect(command.account_id).to eql 'a-100'
          expect(command.type_id).to eql 2
        end
        post :report, id: 't-100',
          amount: '222.32', date: date, tag_ids: ['t-1', 't-2'], 
          comment: 'Comment 100', account_id: 'a-100', type_id: 2, format: :json
        expect(response.status).to eql 200
      end
    end
      
    describe 'PUT adjust' do
      it 'should dispatch report command' do
        date = DateTime.new
        expect(controller).to receive(:dispatch_command) do |command|
          expect(command).to be_an_instance_of AdjustPendingTransaction
          expect(command.id).to eql 't-100'
          expect(command.amount).to eql '222.32'
          expect(command.date).to eql date
          expect(command.tag_ids).to eql ['t-1', 't-2']
          expect(command.comment).to eql 'Comment 100'
          expect(command.account_id).to eql 'a-100'
          expect(command.type_id).to eql 2
        end
        put :adjust, id: 't-100',
          amount: '222.32', date: date, tag_ids: ['t-1', 't-2'], 
          comment: 'Comment 100', account_id: 'a-100', type_id: 2, format: :json
        expect(response.status).to eql 200
      end
    end
      
    describe 'POST approve' do
      it 'should dispatch approve command' do
        expect(controller).to receive(:dispatch_command) do |command|
          expect(command).to be_an_instance_of ApprovePendingTransaction
          expect(command.id).to eql 't-100'
        end
        put :approve, id: 't-100'
        expect(response.status).to eql 200
      end
    end
      
    describe 'PUT adjust-and-approve' do
      it 'should dispatch report command' do
        date = DateTime.new
        expect(controller).to receive(:dispatch_command) do |command|
          expect(command).to be_an_instance_of AdjustAndApprovePendingTransaction
          expect(command.id).to eql 't-100'
          expect(command.amount).to eql '222.32'
          expect(command.date).to eql date
          expect(command.tag_ids).to eql ['t-1', 't-2']
          expect(command.comment).to eql 'Comment 100'
          expect(command.account_id).to eql 'a-100'
          expect(command.type_id).to eql 2
        end
        put :adjust_and_approve, id: 't-100',
          amount: '222.32', date: date, tag_ids: ['t-1', 't-2'], 
          comment: 'Comment 100', account_id: 'a-100', type_id: 2, format: :json
        expect(response.status).to eql 200
      end
    end
    
      
    describe 'DELETE destroy' do
      it 'should dispatch approve command' do
        expect(controller).to receive(:dispatch_command) do |command|
          expect(command).to be_an_instance_of RejectPendingTransaction
          expect(command.id).to eql 't-100'
        end
        delete :destroy, id: 't-100'
        expect(response.status).to eql 200
      end
    end
  end
end