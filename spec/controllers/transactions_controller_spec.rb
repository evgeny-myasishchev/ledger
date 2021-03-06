require 'rails_helper'

describe TransactionsController do
  let(:cmd) { Application::Commands::AccountCommands }
  include AuthenticationHelper
  
  describe "routes", :type => :routing do
    it 'routes root index' do
      expect({get: 'transactions'}).to route_to controller: 'transactions', action: 'index'
    end
    
    it "routes nested index route" do
      expect({get: 'accounts/22331/transactions'}).to route_to controller: 'transactions', action: 'index', account_id: '22331'
      expect(account_transactions_path('22331')).to eql '/accounts/22331/transactions'
    end

    it 'routes root search' do
      expect({get: 'transactions/1-25'}).to route_to controller: 'transactions', action: 'search', from: "1", to: "25"
      expect({post: 'transactions/1-25'}).to route_to controller: 'transactions', action: 'search', from: "1", to: "25"
    end

    it "routes accounts nested search" do
      expect({get: 'accounts/22331/transactions/1-25'}).to route_to controller: 'transactions', action: 'search', account_id: '22331', from: "1", to: "25"
      expect({post: 'accounts/22331/transactions/1-25'}).to route_to controller: 'transactions', action: 'search', account_id: '22331', from: "1", to: "25"
    end
    
    it "routes POST 'report-income'" do
      expect({post: 'accounts/22331/transactions/report-income'}).to route_to controller: 'transactions', action: 'report_income', account_id: '22331'
    end
    
    it "routes POST 'report-expense'" do
      expect({post: 'accounts/22331/transactions/report-expense'}).to route_to controller: 'transactions', action: 'report_expense', account_id: '22331'
    end
    
    it "routes POST 'report-refund'" do
      expect({post: 'accounts/22331/transactions/report-refund'}).to route_to controller: 'transactions', action: 'report_refund', account_id: '22331'
    end
    
    it "routes POST 'report-transfer'" do
      expect({post: 'accounts/22331/transactions/report-transfer'}).to route_to controller: 'transactions', action: 'report_transfer', account_id: '22331'
    end

    it "routes POST 'adjust-[field]'" do
      expect({post: 'transactions/t-100/adjust-amount'}).to route_to controller: 'transactions', action: 'adjust_amount', transaction_id: 't-100'
      expect({post: 'transactions/t-100/adjust-tags'}).to route_to controller: 'transactions', action: 'adjust_tags', transaction_id: 't-100'
      expect({post: 'transactions/t-100/adjust-date'}).to route_to controller: 'transactions', action: 'adjust_date', transaction_id: 't-100'
      expect({post: 'transactions/t-100/adjust-comment'}).to route_to controller: 'transactions', action: 'adjust_comment', transaction_id: 't-100'
    end
    
    it "routes PUT 'convert-type'" do
      expect({put: 'accounts/a-22331/transactions/t-5563/convert-type/type-499843'}).to route_to controller: 'transactions', action: 'convert_type', account_id: 'a-22331', transaction_id: 't-5563', type_id: 'type-499843'
    end
    
    it "routes DELETE 'destroy" do
      expect({delete: 'transactions/t-100'}).to route_to controller: 'transactions', action: 'destroy', transaction_id: 't-100'
    end
    
    it "routes POST 'move-to" do
      expect({post: 'transactions/t-100/move-to/account-332'}).to route_to controller: 'transactions', action: 'move_to', transaction_id: 't-100', target_account_id: 'account-332'
    end
  end
  
  describe "GET 'index'" do
    describe "not authenticated" do
      it "redirects to new session url" do
        get 'index', account_id: 'a-100'
        expect(response).to be_redirect
        expect(response).to redirect_to(new_user_session_url)
      end
    end
    
    describe "authenticated" do
      authenticate_user
      
      it "should get home data for given account" do
        transactions = double(:transactions)
        expect(Projections::Transaction).to receive(:get_root_data).with(user, 'a-100').and_return(transactions)
        get 'index', account_id: 'a-100', format: :json
        expect(response.status).to eql 200
        expect(assigns(:transactions)).to be transactions
      end
      
      it "should get home data for user" do
        transactions = double(:transactions)
        expect(Projections::Transaction).to receive(:get_root_data).with(user, nil).and_return(transactions)
        get 'index', format: :json
        expect(assigns(:transactions)).to be transactions
      end
    end
  end
  
  describe "GET 'search'" do
    authenticate_user
    it "should get transactions search" do
      result = { 'transactions' => [{'t1' => true}, {'t2' => true}] }
      expect(Projections::Transaction).to receive(:search).with(user, 'a-100', 
        criteria: {key1: 'value-1', key2: 'value-2'}, offset: 10, limit: 15, with_total: true
      ).and_return(result)
      
      get 'search', { account_id: 'a-100', from: '10', to: '25', format: :json, 
        criteria: { key1: 'value-1', key2: 'value-2' }, 'with-total' => true
      }
      expect(response.status).to eql 200
      actual_result = JSON.parse(response.body)
      expect(actual_result).to eql result
    end
  end
  
  describe "reporting actions" do
    authenticate_user
    
    describe "POST 'report_income'" do
      it "should build the ReportIncome command from params and dispatch it" do
        command = double(:command)
        expect(cmd::ReportIncome).to receive(:from_hash) do |params|
          expect(params).to be controller.params
          command
        end
        expect(controller).to receive(:dispatch_command).with(command)
        post 'report_income', account_id: 'account-2233', param1: 'value-1', param2: 'value-2'
        expect(response.status).to eql 200
      end
    end
  
    describe "POST 'report_expense'" do
      it "should build the ReportExpence command from params and dispatch it" do
        command = double(:command)
        expect(cmd::ReportExpense).to receive(:from_hash) do |params|
          expect(params).to be controller.params
          command
        end
        expect(controller).to receive(:dispatch_command).with(command)
        post 'report_expense', account_id: 'account-2233', param1: 'value-1', param2: 'value-2'
        expect(response.status).to eql 200
      end
    end 
     
    describe "POST 'report_refund'" do
      it "should build the ReportRefund command from params and dispatch it" do
        command = double(:command)
        expect(cmd::ReportRefund).to receive(:from_hash) do |params|
          expect(params).to be controller.params
          command
        end
        expect(controller).to receive(:dispatch_command).with(command)
        post 'report_refund', account_id: 'account-2233', param1: 'value-1', param2: 'value-2'
        expect(response.status).to eql 200
      end
    end
         
    describe "POST 'report_transfer'" do
      it "should build the ReportTransfer command from params and dispatch it" do
        command = double(:command)
        expect(cmd::ReportTransfer).to receive(:from_hash) do |params|
          expect(params).to be controller.params
          command
        end
        expect(controller).to receive(:dispatch_command).with(command)
        post 'report_transfer', account_id: 'account-2233', param1: 'value-1', param2: 'value-2'
        expect(response.status).to eql 200
      end
    end
  end
  
  describe "adjusting actions" do
    authenticate_user
    
    it "should build dispatch adjust amount command on POST 'adjust_amount'" do
      should_dispatch 'adjust_amount', cmd::AdjustAmount
    end
    
    it "should build dispatch adjust tags command on POST 'adjust_tags'" do
      should_dispatch 'adjust_tags', cmd::AdjustTags
    end
    
    it "should build dispatch adjust date command on POST 'adjust_date'" do
      should_dispatch 'adjust_date', cmd::AdjustDate
    end
    
    it "should build dispatch adjust comment command on POST 'adjust_comment'" do
      should_dispatch 'adjust_comment', cmd::AdjustComment
    end
  end
  
  describe 'ConvertTransactionType' do
    include AuthenticationHelper
    authenticate_user
    
    it "should build and dispatch put 'convert-type'" do
      command = double(:command)
      expect(cmd::ConvertTransactionType).to receive(:new) do |params|
        expect(params).to be controller.params
        command
      end
      expect(controller).to receive(:dispatch_command).with(command)
      put :convert_type, account_id: 'account-100', transaction_id: 't-112', type_id: 4302
      expect(response.status).to eql 200
    end
    
    it "should automatically convert type_id to integer" do
      command = double(:command)
      expect(cmd::ConvertTransactionType).to receive(:new) do |params|
        expect(params[:type_id]).to eql 4302
        command
      end
      allow(controller).to receive(:dispatch_command)
      put :convert_type, account_id: 'account-100', transaction_id: 't-112', type_id: '4302'
      expect(response.status).to eql 200
    end
  end
    
  describe "DELETE 'destroy'" do
    include AuthenticationHelper
    authenticate_user
    
    it "should dispatch the RemoveTransaction command" do
      should_dispatch 'destroy', cmd::RemoveTransaction, :delete
    end
  end
    
  describe "POST 'move-to'" do
    include AuthenticationHelper
    authenticate_user
    
    it "should dispatch the MoveTransaction command" do
      command = double(:command)
      expect(cmd::MoveTransaction).to receive(:new) do |params|
        expect(params).to be controller.params
        command
      end
      expect(controller).to receive(:dispatch_command).with(command)
      post :move_to, transaction_id: 't-112', target_account_id: 'account-110'
      expect(response.status).to eql 200
    end
  end
  
  def should_dispatch(action, command_class, verb = :post)
    command = double(:command)
    expect(command_class).to receive(:new) do |params|
      expect(params).to be controller.params
      command
    end
    expect(controller).to receive(:dispatch_command).with(command)
    send verb, action, transaction_id: 't-112', param1: 'value-1', param2: 'value-2'
    expect(response.status).to eql 200
  end
end
