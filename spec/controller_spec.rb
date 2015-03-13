require './lib/entrance/controller'
require './spec/fake_model'
require 'rspec/mocks'

describe 'Controller' do

  class TestController
    include Entrance::Controller

    def session
      @session ||= {}
    end
  end

  let(:controller) { TestController.new }

  describe 'when included' do

    describe 'if receiver does not respond_to #helper_method' do

      class EmptyClass; end

      it 'does not explode' do
        EmptyClass.should_not_receive(:helper_method).once

        class EmptyClass
          include Entrance::Controller
        end
      end

    end

    describe 'if received responds_to #helper_method' do

      class FooClass
        def helper_method(list)
          # puts 'received'
        end
      end

      it 'calls that method' do
        FooClass.should_receive(:helper_method).once

        class FooClass
          include Entrance::Controller
        end
      end

    end

  end

  # authenticate_and_login(username, password, remember_me = false)
  describe '.authenticate_and_login' do

    describe 'blank username' do

      it 'does not call login!' do
        controller.should_not_receive(:login!)
        controller.authenticate_and_login('', 'test')
      end

    end

    describe 'valid username' do

      describe 'blank password' do

        it 'does not call login!' do
          controller.should_not_receive(:login!)
          controller.authenticate_and_login('test@test.com', '')
        end

      end

      describe 'invalid password' do

        it 'does not call login!' do
          controller.should_not_receive(:login!)
          controller.authenticate_and_login('test@test.com', 'invalid')
        end

      end

      describe 'valid password' do

        it 'calls login!' do
          controller.should_receive(:login!).and_return(FakeUser.new)
          controller.authenticate_and_login('test@test.com', 'test')
        end

        it 'returns user' do
          controller.should_receive(:login!).and_return(FakeUser.new)
          res = controller.authenticate_and_login('test@test.com', 'test')
          res.should be_a FakeUser
        end

        describe 'no remember_me' do

          it 'does not set remember cookie' do
            FakeUser.any_instance.should_not_receive('remember_me!')
            controller.should_not_receive(:set_remember_cookie)
            controller.authenticate_and_login('test@test.com', 'test')
          end

        end

        describe 'remember_me = false' do

          it 'does not call user.set_remember_token' do
            FakeUser.any_instance.should_not_receive('remember_me!')
            controller.should_not_receive(:set_remember_cookie)
            controller.authenticate_and_login('test@test.com', 'test')
          end

        end

        describe 'remember_me = true' do

          describe 'if remember option is disabled' do

          it 'does not set remember cookie' do
            FakeUser.any_instance.should_not_receive('remember_me!')
            controller.should_not_receive(:set_remember_cookie)
            controller.authenticate_and_login('test@test.com', 'test')
          end

          end

          describe 'if remember option is enabled' do

            before do
              Entrance.config.stub(:can?).and_return(true)
            end

            it 'calls set_remember_cookie' do
              FakeUser.any_instance.should_receive('remember_me!').and_return('foobar')
              controller.should_receive(:set_remember_cookie)
              controller.authenticate_and_login('test@test.com', 'test', true)
            end

          end

        end

      end

    end

  end

  # login!(user, remember_me = false)
  describe 'login!' do

    describe 'with invalid user' do

      it 'raises error' do
        expect do
          controller.login! 'foobar'
        end.to raise_error(RuntimeError)
      end

    end

    describe 'with valid user' do

      let(:user) {
        user = FakeUser.new
        user.email = 'aaa@bbb.com'
        user
      }

      it 'calls current_user setter' do
        controller.should_receive(:current_user=).with(user).and_return(true)
        controller.login!(user)
      end

      it 'sets user_id in session' do
        controller.login!(user)
        controller.session[:user_id].should == 'aaa@bbb.com'
      end

      describe 'with remember_me true' do

        # this is basically tested above so we can skip it

      end

    end

  end

  # logout!
  describe 'logout!' do

    describe 'with empty session' do

      before do
        controller.session.should be_empty
      end

      it 'leaves session as it is' do
        controller.logout!
        controller.session.should be_empty
      end

    end

    describe 'with existing user_id in session' do

      before do
        controller.session[:user_id] = '1234'
      end

      it 'sets user_id to nil' do
        controller.logout!
        controller.session[:user_id].should be_nil
      end

    end

  end

  describe 'current_user' do

    describe 'with @current_user instance var not set' do

      before do
        controller.instance_variable_get('@current_user').should be_nil
      end

      it 'calls login_from_session' do
        controller.should_receive(:login_from_session)
        controller.current_user
      end

      describe 'login_from_session succeeds' do

        it 'returns user' do
          controller.should_receive(:login_from_session).and_return(FakeUser.new)
          res = controller.current_user
          res.should be_a FakeUser
        end

        it 'does not call login_with_cookie' do
          controller.should_receive(:login_from_session).and_return(FakeUser.new)
          controller.should_not_receive(:login_from_cookie)
          controller.current_user
        end

      end

      describe 'login_from_session fails' do

        it 'calls login_with_cookie' do
          controller.should_receive(:login_from_session).and_return(nil)
          controller.should_receive(:login_from_cookie)
          controller.current_user
        end

        describe 'login_from_cookie succeeds' do

          it 'returns user' do
            controller.should_receive(:login_from_session).and_return(nil)
            controller.should_receive(:login_from_cookie).and_return(FakeUser.new)
            res = controller.current_user
            res.should be_a FakeUser
          end

        end

      end

    end

    describe 'with @current_user instance var set' do

      before do
        @user = FakeUser.new
        controller.instance_variable_set('@current_user', @user)
      end

      it 'does not call login_from_session' do
        controller.should_not_receive(:login_from_session)
        controller.current_user
      end

    end

  end


  describe 'logged_in?' do

  end

  describe 'logged_out?' do

  end

  describe 'login_required' do

    describe 'if logged in' do

      before do
        controller.stub(:logged_in?).and_return(true)
      end

      it 'does not call access_denied' do
        controller.should_not_receive(:access_denied)
        controller.login_required
      end

    end

    describe 'if logged out' do

      before do
        controller.stub(:logged_in?).and_return(false)
      end

      it 'calls access_denied' do
        controller.should_receive(:access_denied)
        controller.login_required
      end

    end

  end


end
