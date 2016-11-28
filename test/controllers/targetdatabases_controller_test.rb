require 'test_helper'

class TargetdatabasesControllerTest < ActionController::TestCase
  setup do
    @targetdatabase = targetdatabases(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:targetdatabases)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create targetdatabase" do
    assert_difference('Targetdatabase.count') do
      post :create, targetdatabase: {  }
    end

    assert_redirected_to targetdatabase_path(assigns(:targetdatabase))
  end

  test "should show targetdatabase" do
    get :show, id: @targetdatabase
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @targetdatabase
    assert_response :success
  end

  test "should update targetdatabase" do
    patch :update, id: @targetdatabase, targetdatabase: {  }
    assert_redirected_to targetdatabase_path(assigns(:targetdatabase))
  end

  test "should destroy targetdatabase" do
    assert_difference('Targetdatabase.count', -1) do
      delete :destroy, id: @targetdatabase
    end

    assert_redirected_to targetdatabases_path
  end
end
