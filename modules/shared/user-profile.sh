function setUserProfile() {
  touch ~/.profile
  local tmp=$(mktemp)
  setUserProfileInner > $tmp
  mv $tmp ~/.profile
}

function setUserProfileInner() {
  local startLine="# nix user profile start"
  local endLine="# nix user profile end"
  local state="findStart"
  local IFS=$'\n'
  
  for line in $(cat ~/.profile); do
    case $state in
      findStart)
        echo "$line"
        if test "$line" == "$startLine"; then
          cat -
          state="findEnd"
        fi
        ;;

      findEnd)
        if test "$line" == "$endLine"; then
          state="done"
          echo "$endLine"
        fi
        ;;

      done)
        echo "$line"
        ;;
    esac
  done

  case $state in
    findStart)
      echo 
      echo "$startLine"
      cat -
      echo "$endLine"
      echo
      ;;

    findEnd)
      echo "$endLine"
      echo
      ;;
  esac
}

